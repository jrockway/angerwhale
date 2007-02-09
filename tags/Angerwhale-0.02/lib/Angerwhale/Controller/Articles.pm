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

=head2 article_list

Stashes all articles in reverse order.

=cut

sub article_list : Private {
    my ($self, $c) = @_;
    
    $c->stash->{page}	   = 'article_list';
    $c->stash->{template}  = 'search_results.tt';
    $c->stash->{title}	   = 'Archives - '. $c->config->{title};
    
    my @articles = reverse sort $c->model('Filesystem')->get_articles();
    
    $c->stash->{articles}	= [@articles];
    $c->stash->{article_count}	= scalar @articles;
}

=head2 single_article(['raw'])

Displays a single article (with comments, etc.).  If 'raw' is passed
as the argument, then the raw unformatted text is returned as an octet
stream.

=cut

sub single_article : Private  {
    my ($self, $c, @args) = @_;
    my $name    = shift @args;
    my $type    = shift @args;
    
    if(!$name){
	$c->detach('article_list');
    }
    
    $c->stash->{template} = 'article.tt';
    eval {
	$c->stash->{article} = $c->model('Filesystem')->get_article($name);
    };
    if($@){
	# not found!
	$c->stash->{template} = 'error.tt';
	$c->response->status(404);
	return;
    }
    $c->stash->{title} = $c->stash->{article}->title;
    
    # if the user wants the raw message (to verify the signature),
    # return that instead of rendering the template
    if(defined $type && $type eq 'raw'){
	$c->response->content_type('application/octet-stream');
	$c->response->body($c->stash->{article}->raw_text(1));
	return;
    }
}

=head2 default 

XXX: Fix me

Shows all articles at C</articles/> or shows a single
article at C</articles/Article name.format(/raw)?>.

=cut

sub default : Private {
    my ($self, $c, @args) = @_;
    my $page = shift @args;
    die unless $page eq 'articles'; # assert.
    
    if(@args){
	$c->detach('single_article', [@args]);
    }
    
    $c->detach('article_list');
}



=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
