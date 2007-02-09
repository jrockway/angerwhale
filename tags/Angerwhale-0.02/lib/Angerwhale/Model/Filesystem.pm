package Angerwhale::Model::Filesystem;
use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use Carp;
use Angerwhale::Model::Filesystem::Article;
use Crypt::OpenPGP;
use File::Find qw(find);

=head1 NAME

Angerwhale::Model::Filesystem - Filesystem article and comment store

=head1 CONFIGURATION

=head2 base

The directory where the articles are stored.  May contain hidden files
or files (or directories) staring with C<_>, as in C<_users>.  These
files will be ignored by this module.

=cut

__PACKAGE__->mk_accessors(qw(base context));

=head1 METHODS

=head2 new

Used by Catalyst to initialize the article store

=cut

sub new {
    my ($self, $c) = @_;
    $self = $self->NEXT::new(@_);
    
    $self->context($c);
    $self->base($c->config->{base}) if !$self->base;
    
    my $base = $self->base;
    # die if base isn't readable or isn't a directory
    die "$base is not a valid data directory"
      if (!-r $base || !-d $base);
    
    return $self;
}

=head2 get_article

Given the name of an article, retrieves it from the store and returns
it in a C<Angerwhale::Model::Filesystem::Article> object.

=cut

sub get_article {
    my $self	 = shift;
    my $article	 = shift;
    my $base     = $self->base;

    die "article name contains weird characters"
      if $article =~ m{/};

    die "no such article" if !-r "$base/$article" || -d "$base/$article";

    my $result = Angerwhale::Model::Filesystem::Article->
      new({
	   location    => "$base/$article",
	   base        => $self->base,
	   cache       => $self->context->cache,
	   encoding    => $self->context->config->{encoding},
	   userstore   => $self->context->model('UserStore'),
	   filesystem  => $self,
	  });
    
    return $result;
}

sub _ls {
    my $self = shift;
    my $base = shift;
    
    opendir my $dir, $base or die "cannot open $base: $!";
    
    my @articles;
    while(my $article = readdir $dir){
	my $entry = "$base/$article";
	next if $article =~ m{^[.]}; # hidden files are also ignored
	next if !-r $entry;
	next if -d $entry;

	#entry is acceptable
	my $article = $self->get_article($article);
	push @articles, $article;
	
    }
    closedir $dir;
    return @articles;
}

=head2 get_articles

Returns a list of all articles in the store.  The articles are
C<Angerwhale::Model::Filesystem::Article>s.

=cut

sub get_articles {
    my $self = shift;
    my $base = $self->base;

    return _ls($self, $base);
}

=head2 get_categories

Returns a sorted list of the names of all categories.

=cut

sub get_categories {
    my $self = shift;
    my $base = $self->base;

    my @categories;
    opendir my $dir, $base or die "cannot open $base: $!";
    while(my $file = readdir($dir)){
	my $filename = "$base/$file";
	next if $file =~ /^[.]/;
	
	push @categories, $file if (-d $filename && -r $filename);
    }
    return sort @categories;
}

=head2 get_tags

Returns a sorted list of all tags that have been used

=cut

sub get_tags {
    my $self = shift;
    my @articles = $self->get_articles;
    my @tags = map {$_->tags} @articles; 
    my %found;
    @tags = grep {!$found{$_}++} @tags;
    return sort @tags;
}

=head2 get_by_category

Retruns an unsorted list of all articles in a category.

=cut

sub get_by_category {
    my $self = shift;
    my $category = shift;

    my $base = $self->base;
    my $path = "$base/$category";
    die "No category $category" if !-d $path;

    return _ls($self, $path);
}

=head2 get_by_tag

Returns a sorted list of all articles that have been tagged with a
certain tag.  Multiple tags are also OK.

=cut

sub get_by_tag {
    my $self = shift;
    my @tags = map {lc} @_;
    my @matching;

    my @articles = $self->get_articles();
  article: 
    foreach my $article (@articles){
	my $tags = $article->tags();
	foreach my $asked_for (@tags){
	    next article if $tags !~ /(?:\A|;)$asked_for(?:\Z|;)/;
	}
	push @matching, $article;
    }
    
    return @matching;
}

=head2 revision

This method returns a "revision number" for the entire blog.  It will
increase over time, and will remain the same if nothing inside the
blog directory changes.  The revision number will decrease if
an article is removed, so don't remove them without restarting
the application.  (Otherwise the cache will be stale.)

=cut

sub revision {
    my $self = shift;
    my $revision;
    find(sub { $revision += (stat($File::Find::name))[9]
		 if !-d $File::Find::name },
	 ($self->base));
    return $revision;
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
