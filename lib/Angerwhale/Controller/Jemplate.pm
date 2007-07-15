# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Controller::Jemplate;
use strict;
use warnings;

use base 'Catalyst::Controller';

=head2 jemplate

Compile and serve jemplate templates.

=cut

sub jemplate : Global {
    my($self, $c, $file) = @_;
    $c->stash->{jemplate} = { key   =>  $file,
                              files => [$file]};
    $c->forward('View::Jemplate');
    $c->detach if $c->res->body;

    # no template, 404'd.
    $c->clear_errors;
    $c->detach('/not_found');
}

1;
