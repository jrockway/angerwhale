#!/usr/bin/perl
# Context.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Context;
use strict;
use warnings;
use base qw(Class::Accessor);
use Scalar::Util qw(blessed);
use Carp;

__PACKAGE__->mk_accessors('context');

sub new {
    my ($class, $self) = @_;
    my $context = $self->{context};
    croak 'need a valid Angerwhale context'
      if(!defined $context);
    
    bless $self, $class;
    
    $self->context($context);
    $self->userstore($context->model('UserStore'));
    $self->encoding($context->config->{encoding} || 'utf8');
    $self->cache($context->cache);
    
    return $self;
}

1; # magic true value
