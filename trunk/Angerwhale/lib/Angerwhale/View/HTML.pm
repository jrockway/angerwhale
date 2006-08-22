package Blog::View::HTML;
use NEXT;
use strict;
use base 'Catalyst::View::TT::ForceUTF8';
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
