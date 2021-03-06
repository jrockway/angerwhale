package Angerwhale::Controller::Comments;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Angerwhale::Format;
use Scalar::Util qw(blessed);

=head1 NAME

Angerwhale::Controller::Comments - Catalyst Controller

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 find_by_uri_path(@path)

Find a comment based on the current URI.

Puts article and comment in the stash.

=cut

sub find_by_uri_path : Private {
    my ( $self, $c ) = @_;

    my $path = $c->request->uri->path;
    my @path = grep { /[-]/ } ( split m{/}, $path );
    return unless @path;
    
    return $self->find_by_path($c, @path);
}

=head2 find_by_path(@path)

Get a comment based on filesystem (UUID) path.

Puts article and comment in the stash.

=cut

sub find_by_path : Private {
    my ( $self, $c, @path ) = @_;
    return unless @path;

    my @articles = $c->model('Articles')->get_articles;
    my $article = ( grep { $_->id eq $path[0] } @articles )[0];
    $c->stash->{article} = $article;
    shift @path;
    
    while ( $article && (my $path = shift @path) ) {
        my @comments = $article->comments;
        $article = ( grep { $_->id eq $path } @comments )[0];
    }
    

    die "too many args" if @path > 0; # some garbage was on the end of the path
    die "no comment"    if !$article; # we didn't get an actual comment/article
    
    $c->stash->{comment} = $article;
    return $article;
}

=head2 comment

Display a comment based on the current URL

=cut

sub comment : Path {
    my ( $self, $c ) = @_;

    eval { 
        $self->find_by_uri_path($c);
    };
    
    $c->detach('/not_found')
      if $@                             || 
         !defined $c->stash->{comment}  || 
         !blessed $c->stash->{comment}  ||
         !$c->stash->{comment}->isa('Angerwhale::Content::Item');
    
    # handle cases where the find_by_uri_path item is the actual article
    if (!$c->stash->{comment}->isa('Angerwhale::Content::Comment')){
        # handle getting articles by their GUID (instead of name)
        $c->response->
          redirect( $c->uri_for( '/'. $c->stash->{article}->uri ) );
        $c->detach;
    }
    elsif ( $c->request->uri->as_string =~ m{/raw$} ) {
        $c->response->content_type('application/octet-stream');
        $c->response->body( $c->stash->{comment}->raw_text(1) );
        $c->detach;
    }
    
    $c->stash(template => 'comments.tt');
}

=head2 post

Display "post a comment" form, handle posting and previewing.

=cut

sub post : Local {
    my ( $self, $c, @path ) = @_;

    my $method = $c->request->method;
    
    $c->stash->{template} = 'post_comment.tt';
    $c->stash->{action}   = $c->uri_for( "/comments/post/" . join '/', @path );
    $c->stash->{types}    = [ Angerwhale::Format::types() ];
    $c->stash->{captcha}  = $c->forward('/captcha/captcha_uri');
    
    # find what we're replying to
    eval {
        $self->find_by_path($c, @path);
    };
    if ($@) {
        $c->detach('/not_found');
    }
    
    my $article = $c->stash->{article};
    my $comment = $c->stash->{comment};
    
    my $item  = $comment;
    $item = $article if !defined $comment;

    # object is the object we're replying to

    $c->stash->{post_title} = "Re: " . $item->title;

    my $title;
    if ( $method eq 'POST' ) {
        $title = $c->request->param('title');
        my $body    = $c->request->param('body') || ' ';
        my $type    = $c->request->param('type');
        my $captcha = $c->request->param('captcha');

        my $user = $c->stash->{user};
        my $uid  = $user->nice_id if ( $user && $user->can('nice_id') );
        my $comment = $c->model('Articles')->preview({ title  => $title,
                                                       body   => $body,
                                                       type   => $type,
                                                       author => $uid,
                                                     });
        my $errors = 0;
        if($c->stash->{captcha} && !$c->config->{ignore_captcha}){ 
            # captcha required
            my $ok = $c->forward('/captcha/check_captcha', [$captcha]);
            if(!$ok){
                $c->stash->{error} = 'Please enter the text in the security image.';
                $errors++;
            }
            # get rid of captcha if it validated
            $c->stash->{captcha}  = $c->forward('/captcha/captcha_uri');
        }

        if($body =~ /^\s*$/){
            $c->stash->{error} = 'The comment must not be empty.  Say something!';
            $errors++;
        }
        
        my $preview = $c->request->param('Preview');
        if ($preview || $errors > 0) {
            $c->stash->{post_title}      = $title;
            $c->stash->{type}            = $type;
            $c->stash->{preview_comment} = $comment;
            $c->stash->{body}            = $body;
        }
        else {
            my $comment = $item->add_comment( $title, $body, $uid, $type );
            $c->flash->{tracking_url} = 
              $c->req->base. "feeds/comment/xml/". $comment->metadata->{path};
            $c->response->redirect($c->uri_for('/'.$c->stash->{article}->uri));
        }
    }

    return;
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
