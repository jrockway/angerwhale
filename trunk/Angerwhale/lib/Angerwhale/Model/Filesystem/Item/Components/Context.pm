#!/usr/bin/perl
# Context.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Context;
use base qw(Class::Accessor);
use Scalar::Util qw(blessed);
use Carp;

__PACKAGE__->mk_accessors('context');

sub new {
    my ($self, $args) = @_;
    my $context = $args->{context};
    croak 'need a valid Angerwhale context'
      if(!defined $context);
    
    croak('do not directly instantianate this class; '.
	  'you need to mix it in with something else')
      if !blessed $self;
    
    $self->context($context);
    return $self;
}

1; # magic true value
