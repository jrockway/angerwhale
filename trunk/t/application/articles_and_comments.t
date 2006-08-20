#!/usr/bin/perl
# articles_and_comments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests posting of articles and comments against the real server

use Blog;
use Directory::Scratch;
use YAML;
use Test::More (skip_all => "dont know how to make this work");
use Catalyst::Test qw(Blog);

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('base');

Blog->config({base => $base});
Blog->run;

my $r   = get('/');
like($r, qr{No articles in category /}, 'no articles yet');
die;
