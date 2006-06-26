package Blog::Controller::Comments;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Blog::Format;

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

    return;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('find_by_path');
    
    if(!$c->stash->{article}){
	$c->stash->{template} = "error.tt";
	$c->response->status(404);
    }
    else {
	
	if($c->request->uri->as_string =~ m{/raw$}){
	    $c->response->content_type('text/plain');
	    $c->response->body($c->stash->{comment}->raw_text);
	}
	
	else {
	    $c->stash->{template} = "comments.tt";
	}
    }
    
    return;
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
    
    $c->stash->{post_title} = "Re: ". $object->title;

    my $title;
    if($method eq 'POST'){
	$title = $c->request->param('title');
	my $body = $c->request->param('body');
	my $type = $c->request->param('type'); 
	$title =~ s/[><&]//g;

	my $user = $c->stash->{user};
	my $id   = $user->nice_id if ($user && $user->can('nice_id'));

	my $preview = $c->request->param('Preview');
	if($preview){
	    $c->stash->{post_title} = $title;
	    $c->stash->{type}  = $type;

	    $c->stash->{comment} = 
	      Blog::Model::Filesystem::PreviewComment->new($c, $title,
							   $body, $type);
	    
	    $body =~ s/&/&amp;/g;
	    $body =~ s/</&lt;/g;
	    $body =~ s/>/&gt;/g;
	    
	    $c->stash->{body}  = $body;
	}
	else {
	    $object->add_comment($title, $body, $id, $type);
	    $c->response->redirect($c->stash->{article}->uri);
	}
    }
    
    $c->stash->{template} = 'post_comment.tt';
    $c->stash->{action} = $c->request->uri->path;
    $c->stash->{types}  = [Blog::Format::types()];
    return;
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
