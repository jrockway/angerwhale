package Blog::Controller::Comments;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Blog::Controller::Comments - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub find_by_path : Private {
    my ($self, $c) = @_;

    my $path = $c->request->uri->path;
    my @path = grep {/[-]/} (split m{/}, $path);
    
    my $root     = $c->stash->{root};
    my @articles = $root->get_articles;
    my $article  = (grep { $_->id eq $path[0]; } @articles)[0];
    $c->stash->{article} = $article;
    shift @path;

    while(my $path = shift @path){
	my @comments = $article->comments;
	$article = (grep {$_->id eq $path} @comments)[0];

    }
    $c->stash->{comment} = $article;    

    return 0;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('find_by_path');
    
    if(!$c->stash->{article}){
	$c->stash->{template} = "error.tt";
	$c->response->status(404);
	return;
    }

    $c->stash->{template} = "comments.tt";
}

sub post : Local('post'){
    my ( $self, $c ) = @_;

    my $method = $c->request->method;

    # find what we're replying to
    $c->forward('find_by_path');
    my $article = $c->stash->{article};
    my $comment = $c->stash->{comment};
    my $object = $comment;
    $object = $article if !defined $comment;

    # object is the object we're replying to

    if($method eq "POST"){
	my $title = $c->request->param("title");
	my $body  = $c->request->param("body");

	$title =~ s/[><&]//g;

	my $user = $c->stash->{user};
	my $id   = $user->nice_id if ($user && $user->can('nice_id'));

	$object->add_comment($title, $body, $id);
	$c->response->redirect($c->stash->{article}->uri);
    }
    
    $c->stash->{template} = "post_comment.tt";
    $c->stash->{post_title} = "Re: ". $object->title;
    $c->stash->{action} = $c->request->uri->path;
    #$c->response->body("comment is ". $article->title);
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
