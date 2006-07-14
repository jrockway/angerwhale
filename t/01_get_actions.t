#!/usr/bin/perl
# 01_get_actions.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests all actions that are read-only

use strict;
use warnings;
use Test::More tests => 16;

BEGIN { use_ok 'Catalyst::Test', 'Blog' }
BEGIN { use_ok 'Blog::Controller::Articles' }
BEGIN { use_ok 'Blog::Controller::Categories' }
BEGIN { use_ok 'Blog::Controller::Comments' }
BEGIN { use_ok 'Blog::Controller::Feeds' }
BEGIN { use_ok 'Blog::Controller::Login' }
BEGIN { use_ok 'Blog::Controller::Tags' }
BEGIN { use_ok 'Blog::Controller::Users' }

ok( request('/')->is_success, 'Requesting /');
ok( request('/articles/')->is_success, 'Requesting /articles/');
ok( request('/tags')->is_success);
ok( request('/tags/get_nav_box')->is_success);
ok( request('/tags/tag_list')->is_success);
ok( request('/login')->is_success, 'Request should succeed' );
ok( request('/login/nonce')->is_success, 'Request should succeed' );
ok( request('/users')->is_success, 'Request should succeed' );
