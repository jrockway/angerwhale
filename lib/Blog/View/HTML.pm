package Blog::View::HTML;
use NEXT;
use strict;
use base 'Catalyst::View::TT';
use File::Temp;

__PACKAGE__->config( 
		    TOLERANT => 1,
		    #TIMER => 1, 
		    STRICT_CONTENT_TYPE => 1,
		    RECURSION => 1,
		    DEBUG => 1,    
		    COMPILE_DIR => File::Temp::tempdir(CLEANUP => 1),
		    PLUGIN_BASE => 'Blog::Filter',
		   );

sub process {
    my ($self, $c) = @_;
    if (!$c->response->content_type){
	# this breaks IE, but fuck IE.
	$c->reponse->content_type('application/xhtml+xml; charset=utf-8');
    }
    $self->NEXT::process($c);
}

=head1 NAME

Blog::View::HTML - Catalyst TT View

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst TT View.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
