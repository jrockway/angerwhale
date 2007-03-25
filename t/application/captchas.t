#!/usr/bin/env perl
# captchas.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 16;
use Angerwhale::Test;

my $mech = Angerwhale::Test->new;
my $tmp  = $mech->tmp;

$mech->get_ok('http://localhost/');
my $a_title = "This is a test article for you.";
my $a_body  = 'This is a test article. Yayyy.';
$tmp->touch( $a_title, $a_body );
my $article = $tmp->exists($a_title);
ok( $article, 'created article OK' );
$mech->get_ok("http://localhost/articles/$a_title");
$mech->content_contains( 'Post a comment', 'page contains post comment link' );
$mech->follow_link_ok( { text => 'Post a comment' }, 'trying to post a comment' );

my $c_title = "test comment $$";
my $c_body  = "This is a test comment: $$";
ok(
   $mech->submit_form(
                      fields => {
                                 title => $c_title,
                                 body  => $c_body,
                                 type  => 'text',
                                 captcha => 'bad guess',
                                },
                      button => 'Preview'
                     ),
   'submit comment for preview OK'
  );

$mech->content_contains( $c_title, 'preview has comment title' );
$mech->content_contains( $c_body,  'preview has body' );
$mech->content_contains( 'Please enter the text in the security image.', 
                         'warning about captcha');

ok( $mech->submit_form( button => 'Post' ), 'post the comment for real' );
$mech->get_ok("http://localhost/articles/$a_title");
$mech->content_contains( 'no comments', 'page contains no comments' );

$mech->get_ok("http://localhost/captcha");
like($mech->ct, qr/^image/, 'content is an image');
my $content = $mech->content();
$mech->get_ok("http://localhost/captcha");
is($content, $mech->content, 'same captcha returned each time');

