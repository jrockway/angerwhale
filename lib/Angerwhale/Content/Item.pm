# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Item;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Class::C3;
use Data::UUID;
__PACKAGE__->mk_accessors(qw/data metadata children/);

=head2 id

return the UUID of this item

=cut

sub id {
    my $self = shift;
    my $id = $self->metadata->{guid};
    return $id if $id;

    $id = Data::UUID->new->create_str();
    $self->store_attribute('guid', $id);
    return $id;
}

=head2 store_attribute

Store a piece of metadata

=cut

sub store_attribute {
    my $self = shift;
    my $attr = shift;
    my $value= shift;

    $self->metadata->{$attr} = $value;
    $self->maybe::next::method($attr,$value);
    return;
}

=head2 store_data

Rewrite the data section of this item

=cut

sub store_data {
    my $self = shift;
    my $data = shift;
    
    $self->data($data);
    #$self->next::method($data);

    return;
}

1;

