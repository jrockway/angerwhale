package Blog::View::Feed::RSS;

use strict;
use base qw(Blog::View::Feed Catalyst::View::TT);
use File::Temp;
use Blog;

__PACKAGE__->config( 
		    TOLERANT => 1,
		    #TIMER => 1, 
		    DEBUG => 1,    
		    INCLUDE_PATH => [ Blog->path_to('root', 'xml') ],
		    COMPILE_DIR => File::Temp::tempdir(CLEANUP => 1),
		   );

sub process {
    my ($self, $c) = @_;
    $c->stash->{items}    = [$self->prepare_items($c)];
    $c->stash->{template} = 'rss20.tt';
    
    $self->stash_rss_header($c);
    $c->response->content_type('application/rss+xml');
    
    return $self->SUPER::process($c);
}

sub stash_rss_header {
    my ($self, $c) = @_;
    
    $c->stash->{title}		 = ($c->config->{title} || 'Blog'). ' RSS Feed';
    $c->stash->{link}		 = $c->req->base;
    $c->stash->{description}	 = $c->config->{description} || 'RSS Feed';
    $c->stash->{generator}	 = 'AngerWhale version '. $c->config->{VERSION};
    $c->stash->{webMaster}	 = $c->config->{contact}. 
      '('.$c->config->{author}.')';
    $c->stash->{managingEditor}	 = $c->config->{contact}. 
      '('.$c->config->{author}.')';
    $c->stash->{langauge}	 = $c->config->{language} || 'C';

    return;
}

1;

__END__

=head1 NAME

Blog::View::Feed::RSS - TT-based RSS feed generator (because L<XML::Feed>
and L<XML::RSS> are bad)

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
