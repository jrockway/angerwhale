#!/usr/bin/perl
# articles_and_comments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests posting of articles and comments against the real server

use Angerwhale;
use Directory::Scratch;
use YAML;
use Test::More (skip_all => "dont know how to make this work");
use Catalyst::Test qw(Angerwhale);

my $tmp  = Directory::Scratch->new;
my $base = $tmp->mkdir('base');

Angerwhale->config({base => $base});
Angerwhale->run;

my $r   = get('/');
like($r, qr{No articles in category /}, 'no articles yet');
die;
