# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Item;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Class::C3;
use Carp;
use Data::UUID;
__PACKAGE__->mk_accessors(qw/data metadata children/);

=head1 NAME

Angerwhale::Content::Item - abstract base class for Content Items

=head1 METHODS

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

=head2 _add_tag(tag,count)

Internal method for adding a (tag,count) pair to
the metadata area.  Needed so that:

  FOO => 2
  fOo => 3

Results in:
  
   foo => 5

Make sure you call this method with character data, not bytes

XXX: people are calling this with count=undef.  Why?

=cut

sub _add_tag {
    my ($self, $tag, $count) = @_;
    $tag = lc $tag; # canonicalize
    
    my $cur_count = $self->{metadata}{tags}{$tag}||0;
    $self->{metadata}{tags}{$tag} = $cur_count + ($count||0);
    
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

=head2 children

Return (or set; INTERNAL USE ONLY) reference to the list of children.
When setting, returns nothing.

You can set children to a coderef that is passed C<$self> and returns
an arrayref of children.  This will be cached.  (This is to replace
Scalar::Defer for lazily-filtering children, BTW.)

Note: your subclass needs to implement _children, which returns a raw
array of Items.

This is messy.  Ugh.

=cut

sub children {
    my $self = shift;
    my $kids = shift;

    if ($kids) {
        if (ref $kids eq 'CODE') {
            $self->{_defer_children} = $kids;
        }
        elsif(ref $kids eq 'ARRAY'){
            $self->{children} = $kids;
        }
        else {
            croak "bad data passed to Item::children";
        }
        return;
    }

    # if children is an arrayref, return them directly
    return $self->{children} if ref $self->{children};
    
    if(ref $self->{_defer_children} eq 'CODE'){
        my $code = delete $self->{_defer_children};
        $self->{children} = [$self->_children] if $self->can('_children');
        $self->{children} = $code->($self);
        return $self->{children};
    }

    return [];
}

=head1 METHODS YOU SHOULD IMPLEMENT

=head2 add_comment

See Angerwhale::Content::Filesytem::Item for now

=cut

1;

