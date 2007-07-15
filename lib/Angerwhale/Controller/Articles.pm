package Angerwhale::Controller::Articles;

use strict;
use warnings;
use base 'Catalyst::Controller';
use URI::Escape;

=head1 NAME

Angerwhale::Controller::Articles - Catalyst Controller

=head1 SYNOPSIS

See L<Angerwhale>

Core article manager, for displaying archives, and blog pages.

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 all_articles

Shows every article.

=cut

sub all_articles : Path Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{page}     = 'article_list';
    $c->stash->{template} = 'search_results.tt';
    $c->stash->{title}    = 'Archives - ' . $c->config->{title};

    my @articles = reverse sort $c->model('Articles')->get_articles();

    $c->stash->{articles}      = [@articles];
    $c->stash->{article_count} = scalar @articles;
}

=head2 article_setup($article)

Start of a chain that gets an article and stashes it.

=cut

sub article_setup :Chained('/') PathPart('articles') CaptureArgs(1) Args(1) {
    my ($self, $c, $article) = @_;
        eval { $c->stash->{article} = 
                 $c->model('Articles')->get_article($article); };
    if ($@) {
        # no article by this name, show 404
        $c->detach('/not_found');
    }
    $c->stash->{title} = $c->stash->{article}->title;
}

=head2 single_article 

When the chain has no args after the article, just display
the article as HTML.

=cut

sub single_article :Chained('article_setup') :PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash(template => 'article.tt');
}

=head2 raw

If "raw" shows up as the argument after the article name,
then return the raw text of the article

=cut

sub raw :Chained('article_setup') Args(0) {
    my ($self, $c) = @_;
    $c->response->content_type('application/octet-stream');
    $c->response->body( $c->stash->{article}->raw_text(1) );
    $c->detach;
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
