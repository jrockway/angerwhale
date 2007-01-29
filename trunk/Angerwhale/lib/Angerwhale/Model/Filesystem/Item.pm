#!/usr/bin/perl
# Item.pm - a Filesystem item (Article or Comment, usually)
# Copyright (c) 2006 Jonathan Rockway

package Angerwhale::Model::Filesystem::Item;
use strict;
use warnings;
use Carp;
use Class::C3;

# mixin our methods
use base qw|
	    Angerwhale::Model::Filesystem::Item::Components::Encoding
	    Angerwhale::Model::Filesystem::Item::Components::Tags
	    Angerwhale::Model::Filesystem::Item::Components::Comments
	    Angerwhale::Model::Filesystem::Item::Components::Metadata
	    Angerwhale::Model::Filesystem::Item::Components::Content
	    Angerwhale::Model::Filesystem::Item::Components::GUID
	    Angerwhale::Model::Filesystem::Item::Components::Signature
	    Class::Accessor
	   |; 

# setup internal state
__PACKAGE__->mk_accessors(qw|base location parent filesystem
			     userstore encoding cache|);
#Class::C3::initialize();

# make C<sort @articles> sort by creation time
use overload (q{<=>} => \&compare,
	      q{cmp} => \&compare,
	      # but still let other stuff work too	    
	      fallback => "TRUE");

=head1 NAME

Angerwhale::Model::Filesystem::Item - a filesystem item that knows how
to attach other C<Item>s to itself

=head1 SYNOPSIS

=head1 METHODS

=head2 new( \%arguments )

Creates a new Filesystem::Item; but you probably want
C<Filesystem::Item::Article> or C<Filesystem::Item::Comment> instead.

Arguments:

=over 4

=item base 

[REQUIRED] The directory to read filesystem items from.

=item location

[REQUIRED] The file used to back this I<Item>.  Must exist, and must be a
regular file.

=item parent

The object that this I<Item> is attached to, if any.

=back

=cut

sub new {
    my ($class, $args) = @_;
    
    croak "Unexpected path: $args->{path}" if $args->{path};
    my $base      = $args->{base};
    my $location  = $args->{location};
    my $parent    = $args->{parent};
    my $cache     = $args->{cache};
    my $userstore = $args->{userstore};
    my $encoding  = $args->{encoding};
    my $filesystem= $args->{filesystem};
    
    croak "$base is not a valid base directory" 
      if(!defined $base || !-d $base || !-r $base);
    croak "$location is not a valid path"     
      if(!defined $location || -d $location);
    croak 'Need a userstore' unless $userstore;
    croak 'Need a cache' unless $cache;
    
    $args->{encoding} ||= 'utf8';

    my $self = $args;
    bless $self, $class;
    $class->next::method($self);
    return $self;
}

=head2 name

Returns the filename of this Item.

=cut

sub name {
    my $self = shift;
    my $name;

    $self->location =~ m{([^/]+)$};
    $name = $1;
        
    return $name;
}

=head2 compare

Sorting function.  Sorts by reverse creation_time (newest first).

=cut

sub compare {
    my $a = shift;
    my $b = shift;

    return $a->creation_time <=> $b->creation_time;
}

1;
