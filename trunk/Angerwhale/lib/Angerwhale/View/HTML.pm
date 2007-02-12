package Angerwhale::View::HTML;
use NEXT;
use strict;
use base 'Catalyst::View::TT';
use File::Spec;

__PACKAGE__->config(
    TOLERANT            => 1,
    TIMER               => 0,
    STRICT_CONTENT_TYPE => 1,
    RECURSION           => 1,
    DEBUG               => 1,
    COMPILE_DIR         => File::Spec->catfile(File::Spec->tmpdir, 
                                               'angerwhale', 'templates'),
    PLUGIN_BASE         => 'Angerwhale::Filter',
);

=head1 NAME

Angerwhale::View::HTML - Catalyst TT View

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst TT View.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
