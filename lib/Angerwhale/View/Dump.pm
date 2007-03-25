# Dump.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::View::Dump;

use base qw(Catalyst::View);

use strict;
use YAML::Syck;

=head1 View::Dump

Return a page as a YAML dump of the stash.

=head1 METHODS

=head2 process

Standard process method.

=cut

sub process {
    my $self = shift;
    my $c    = shift;

    $c->response->content_type('text/plain');
    $c->response->body( YAML::Dump( $c->stash ) );

    return;
}

1;
