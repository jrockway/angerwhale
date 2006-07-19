#!/usr/bin/perl
# model_UserStore.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use ok 'Blog::Model::UserStore';
use Test::MockObject;
use Directory::Scratch;
use Blog::Challenge;

my $c = Test::MockObject->new;

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir; 
my $config = { base => $base };
$c->set_always('config', $config);

my $ns = Blog::Model::UserStore->new($c);
isa_ok($ns, 'Blog::Model::UserStore');
