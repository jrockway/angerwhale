#!/usr/bin/perl
# Challenge.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::Challenge;
use strict;
use warnings;
use Crypt::Random qw(makerandom);
use DateTime;
use YAML;

use overload (q{==} => "equals", q{""} => "tostring");

sub new {
    my ($class, $args) = @_;
    my $self = {};
    
    my $random = makerandom(Size => 128, Strength => 0);
    my $now    = DateTime->now;
 
    $self->{nonce} = "$random";
    $self->{uri}   = $args->{uri} || die "specify URI";
    $self->{date}  = "$now";
    
    bless $self, $class;
}

sub equals {
    my $self = shift;
    my $them = shift;

    return 
      ($self->{nonce} == $them->{nonce}) &&
      ($self->{uri}   eq $them->{uri}  ) &&
      ($self->{date}  eq $them->{date} ) ;
}

sub tostring {
    my $self = shift;
    return Dump($self);
}

1;
