package Blog::Controller::Articles;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;

=head1 NAME

Blog::Controller::Articles - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub articles : Private {
    my ($self, $c) = @_;
    
    $c->stash->{page} = "article_list";
    $c->stash->{template} = "search_results.tt";
    $c->stash->{title} = "Blog Archives";
    
    my @articles = reverse sort $c->stash->{root}->get_articles();
    
    $c->stash->{articles} = \@articles;
    $c->stash->{article_count} = scalar @articles;
}

sub show_article : LocalRegex('[^.]') {
    my ($self, $c) = @_;
    my $name = uri_unescape($c->request->uri);
    
    $name =~ m{/([^/]+)$};
    $name = $1;
    $c->stash->{template} = "article.tt";
    eval {
	$c->stash->{article} = $c->stash->{root}->get_article($name);
    };
    if($@){
	# not found!
	$c->stash->{template} = "error.tt";
	$c->response->status(404);
	return;
    }
    $c->stash->{title} = $c->stash->{article}->title;
}

sub default : Private {
    my ($self, $c) = @_;
    
    if($c->request->uri !~ m{articles/$}){
	$c->response->redirect('/articles/');
    }
    else {
	$c->forward("articles");
    }
}



=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
