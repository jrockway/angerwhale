#!/usr/bin/perl
# Context.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Context;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessor('context');

sub new {
    my ($class, $args) = @_;
    my $context = $args->{context};
    croak "need a valid Angerwhale context"
      if(!defined $context);
    $self->context($context);

    bless $self, $class;
    return $self;
}
