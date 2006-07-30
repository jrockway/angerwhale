package Blog::Controller::Categories;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;

=head1 NAME

Blog::Controller::Categories - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub show_category : Private {
    my ($self, $c) = @_;
    my $category = $c->stash->{category};
    my $start    = $c->request->param("offset");
    $start = 0 if !defined $start;
    $start = 0 if $start < 0;
    
    my $uri = $c->request->uri;
    if($start == 0 && defined $uri->query){
	$c->response->redirect($uri->path || '/');
    }

    my @articles;
    $c->stash->{template} = "blog_listing.tt";
    
    if($category =~ m"/"){ # redirected from Root.pm
	@articles = reverse sort $c->stash->{root}->get_articles();
    }
    else {
	$c->stash->{title} = "Entries in $category";
    
	@articles = reverse sort $c->stash->{root}->get_by_category($category);
    }
    
    # no articles
    if(@articles < 1){
	$c->stash->{message} = "No articles in $category.";
    } 
    my $total = scalar @articles;
    
    if($start > 0 && $start < @articles){
	$c->stash->{previous} = $start;
	@articles = @articles[$start..$#articles];
    }

    # lots of articles?
    if(@articles > 4){
	@articles = @articles[0..4];
    }
    
    # nav links < 8 newer | 5 older > (etc.)
    $c->stash->{final_offset} = $total - 5;
    $c->stash->{next_offset} = $start + 5;
    if($c->stash->{next_offset} > $c->stash->{final_offset}){
	$c->stash->{next_offset} = $c->stash->{final_offset};
    }
    $c->stash->{previous_offset} = $start - 5;
    if($c->stash->{previous_offset} < 0){
	$c->stash->{previous_offset} = 0;
    }

    $c->stash->{next} = $total - 5 - $start if $total - 5 - $start > 0;
    $c->stash->{articles} = \@articles;
}

sub list_categories : Private {
    my ($self, $c) = @_;
    $c->response->body('The list of categories is conveniently located to your left.');
}


sub yaml : Local {
    my ($self, $c) = @_;
    $c->detach('/feeds/articles_yaml', $c->stash->{articles});
}


sub default : Private {
    my ($self, $c) = @_;    
    my $path = uri_unescape($c->request->path);
    $c->forward('list_categories');
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
