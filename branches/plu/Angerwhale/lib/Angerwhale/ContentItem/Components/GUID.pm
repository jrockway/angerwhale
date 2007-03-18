#!/usr/bin/perl
# GUID.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::Components::GUID;
use strict;
use warnings;
use Data::GUID;
use File::Attributes qw(get_attribute set_attribute);

=head1 GUID

GUID component for ContentItem.  Mix in to get a GUID
for each item.

=head1 METHODS

=head2 id

Returns the GUID for this item.

Attribute: guid

=cut

sub id {
    my $self = shift;
    my $path =
      ( -l $self->location )
      ? readlink( $self->location )
      : $self->location;
    my $guid;
    eval {
        $guid = get_attribute( $self->location, 'guid' );
        $guid = Data::GUID->from_string($guid);
    };
    return $guid->as_string if ( !$@ && $guid->as_string );

    $guid = Data::GUID->new;

    eval { set_attribute( $self->location, 'guid', $guid->as_string ) };
    die "Problem setting guid on $path: $@" if $@;

    return $guid->as_string;
}

1;    # magic true value
