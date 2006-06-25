package Blog::View::HTML;

use strict;
#use base 'Catalyst::View::TT';
use base 'Catalyst::View::TT::ForceUTF8';
use YAML;

__PACKAGE__->config( 
		    TOLERANT => 1,
#		    TIMER => 1, 
		    STRICT_CONTENT_TYPE => 1,
		    RECURSION => 1,
		    DEBUG => 1,
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
