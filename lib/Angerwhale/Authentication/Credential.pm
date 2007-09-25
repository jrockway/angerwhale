# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Authentication::Credential;
use strict;
use warnings;

use Class::C3;
use base 'Class::Accessor';

sub verify {
    my $self = shift;
    my $id   = shift;

    return unless $id;
    return $self->name. ":$id";
}

1;
