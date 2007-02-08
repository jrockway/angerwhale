package Angerwhale::Controller::Categories;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;
use Time::Local;
use YAML::Syck;
use Scalar::Util qw(blessed);

=head1 NAME

Angerwhale::Controller::Categories - Catalyst Controller

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 show_category

Gets a list of articles to show.  The first argument is the name of
the category to display, or q{} (an empty string) for the "root"
category.  If there's another argument, it should be a date in the
form:

     (YYYY, MM, DD)

Processing of articles will begin on this date, such that all articles
on that day are shown, then YYYY, MM, DD-1; and so on, until
C<articles_per_page> articles have been selected for display.  If
there are more than C<articles_per_page> articles from a single day, they
will all be displayed regardless of the C<articles_per_page> setting.
(Just for general sanity; not likely to happen in real life.)

Config options that are used:

=over

=item mini_cutoff

If an articles has fewer than this number of words, it is displayed in
"mini" form, unless it's the first article on the page.  Defaults to 150.

=item articles_per_page

How many articles to display before the "42 older articles" link is
displayed.  Can be overridden by sepcifying C<articles_desired> in the
stash.  Defaults to 5.

=back

To deal with paging, C<newer_articles> and C<older_articles> are set
to the dates of newer and older articles.

=cut

# this is a little messy.  i should probably clean this up.
sub show_category : Private {
    my ($self, $c, @start_date) = @_;
    $c->stash->{template} = q{blog_listing.tt};
    if(@start_date == 3){
	$c->stash->{page} = "home, but with date"; # for navbar 
    }

    # how many (non-mini) articles to return?
    my $ARTICLES_PER_PAGE = $c->stash->{articles_desired} || 
      $c->config->{articles_per_page} || 5;

    # how many words must an article contain to be non-mini?
    my $MINI_CUTOFF = $c->config->{mini_cutoff} || 120; 

    # get the articles
    my $category = $c->stash->{category};
    my $article; # tmp counter variable in a few places
    my @articles;
    
    if($category eq '/'){ # redirected from Root.pm
	@articles = reverse sort $c->stash->{root}->get_articles();
    }
    else {
	$c->stash->{title} = "Entries in $category";
    
	@articles = reverse sort $c->stash->{root}->get_by_category($category);
    }

    # mini-ize small articles
    foreach my $article (@articles){
	$article->mini(1) if $article->words < $MINI_CUTOFF;
    }

    # first article can never be mini.  too ugly.
    # (but, on archive pages, keep it mini for consistency)
    $articles[0]->mini(0) if $articles[0];

    my $config;
    $config->{articles_per_page} = $ARTICLES_PER_PAGE;
    $config->{date} = [@start_date] if @start_date;

    my ($too_new, $current, $too_old) 
      = $self->_split_articles([@articles], $config);
    
    my @too_new = @{$too_new};
    my @current = @{$current};
    my @too_old = @{$too_old};

    ## no articles to display
    if(@current == 0){
	$c->stash->{message} = 'No articles to display.';
	# TODO: generate "click here for new articles" message if
	# that's why there aren't any articles to show
	return;
    } 
    
    ## find the date of the older articles page
    if($too_old[0]){
	$c->stash->{older_articles} = _date_of($too_old[0]);
    }

    ## find the date of the newer articles page
    @too_new = reverse @too_new;
    my @previous_page;
    {
	my $max = $ARTICLES_PER_PAGE;
	my $article;
	while($article = shift @too_new){
	    last if !$max;
	    $max-- if !$article->mini;
	    
	    push @previous_page, $article;
	}
	unshift @too_new, $article;
    }
    
    my $last  = $previous_page[-1];
    my $first = $previous_page[0];
    my $after = $too_new[0];
    
    if(!$after && $first && $last){
	$c->stash->{newer_articles}   = _date_of($last);
	$c->stash->{newest_is_newest} = 1;
    }
    elsif(!$after && !$first && !$last){
	# nothing newer
    }
    # the nested else handles one of these cases... maybe i should split?
    elsif(_on_same_day($first, $after) || _on_same_day($after, $last)){
	# step through previous page, oldest -> newest, looking for a
	# date that won't spill (the first date != to date_of(i)
	my $article;
	foreach $article (reverse @previous_page){
	    last if !_on_same_day($article, $last);
	}
	if($article){
	    $c->stash->{newer_articles} = _date_of($article);
	}
	else {
	    # just to be safe, do $first, not $last.
	    $c->stash->{newer_articles} = _date_of($first);
	}
    }
    else {
	$c->stash->{newer_articles} = _date_of($last);
    }
    
    $c->stash->{articles} = [@current];
    return [@current];
}

=head2 _split_articles

     ($before_ref, $current_ref, $after_ref) =
     _split_articles($articles_ref, $args_ref)

Splits the array reference C<$articles_ref> into three arrays, before,
current, and after.  The article list should be sorted, with the most
recent article first.  If this isn't the case, expect something bad to
happen.

C<$args_ref> is a hash reference containing:

=over

=item date

An array reference to the date array: [year, month, day].

For example, [2006, 07, 31] is July 31, 2006.

=item articles_per_page

How many articles to put on the "current" page.

=back

XXX: Note that I'm being lazy about checking validity of paramaters.  Don't
set articles_per_page to be -42 or sort the array backwards.  If you
do that, expect something bad to happen.  RTFM.

Throws an exception if the date is not valid.

=cut

sub _split_articles {
    my ($self, $articles, $config) = @_;
    my $ARTICLES_PER_PAGE = $config->{articles_per_page} || die;
    my @articles = @{$articles};
    my @date     = @{$config->{date}} if ref $config->{date};
    
    my @before;  # articles *newer* than current ($before[0] is newest)
    my @current; # current articles (to display)
    my @after;   # articles older than current ($after[-1] is oldest)
    
    # setup before
    if(@date == 3){
	die "invalid date @date" if @date != 3;
	my $date = timelocal(59, 59, 23,$date[2], $date[1]-1, $date[0]-1900) 
	              + 1; # always compare with <, not <=.
      before:
	while(my $article = shift @articles){
	    if($article->creation_time > $date){
		push @before, $article;
	    }
	    else {
		unshift @articles, $article;
		last before;
	    }
	}
    }
    
    # setup current
    {
	my $max = $ARTICLES_PER_PAGE;
	my $article;
      current:
	while($article = shift @articles){
	    last if !$max;
	    $max-- if !$article->mini;

	    push @current, $article;
	}
	unshift @articles, $article; # shouldn't have been shifted

	# check to see if all the articles from $date are on the page
	if(@date){
	    while(($article = shift @articles) &&
		  _on_same_day($current[0], $article)){
		push @current, $article;
	    }
	    unshift @articles, $article; # shouldn't have been shifted
	}
    }
    
    @after = @articles;
    
    return ([@before], [@current], [@after]);
}

sub _on_same_day {
    my ($a, $b) = @_;

    return 0 if !blessed($a) || !blessed($b);

    my @a = (localtime($a->creation_time))[3,4,5];
    my @b = (localtime($b->creation_time))[3,4,5];

    return ($a[0] == $b[0]) &&
           ($a[1] == $b[1]) &&
	   ($a[2] == $b[2]);
}

=head2 _date_of

Given an article, returns the date in yyyy/mm/dd format.

=cut

sub _date_of {
    my $article = shift;
    my @a = (localtime($article->creation_time))[5,4,3];
    return sprintf('%d/%0d/%0d', $a[0]+1900, $a[1]+1, $a[2]);
}

=head2 list_categories

 XXX: todo.

=cut

sub list_categories : Private {
    my ($self, $c) = @_;

    $c->response->body(<<'    EOF');
    The list of categories is conveniently located to your left.
    EOF

    return;
}

=head2 default($category)

Display the C<$category> or an error message if it doesn't exist.

=cut

# XXX: change show_category to do this directly
sub default : Private {
    my ($self, $c, @args) = @_;    

    my $action   = shift @args; 
    my $category = shift @args;
    my @date     = @args;
    
    if(!$category || $action ne 'categories'){
	$c->forward('list_categories');  # 404'd.
    }
    else {
	$c->stash->{category} = $category;
	$c->forward('show_category', [@date]);
    }
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
