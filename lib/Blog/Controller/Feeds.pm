package Blog::Controller::Feeds;

use strict;
use warnings;
use base 'Catalyst::Controller';
use YAML;

=head1 NAME

Blog::Controller::Feeds - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub yaml : Local {
    my ($self, $c) = @_;
    $c->stash->{category} = q{/};
    $c->forward('/categories/show_category');
    
    my $response = q{};
    foreach my $article (@{$c->stash->{articles}}){
	my $data;
	my $author = $article->author;
	
	if(!$author->isa('Blog::User::Anonymous')){
	    $data->{author} = $author->key;
	}

	$data->{title}   = $article->title;
	$data->{summary} = $article->summary;
	$data->{signed}  = $article->signed ? 1 : 0;
	$data->{post}    = $article->text;
	$data->{raw}     = $article->raw_text;
	$data->{guid}    = $article->id;
	$data->{uri}     = $c->request->base. $article->uri;
	$response .= Dump($data). "\n";
    }
    $c->response->body($response);
    return;
}


=head1 AUTHOR

Jonathan Rockway,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
