#!/usr/bin/perl
# 01_get_actions.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 15;

use Catalyst::Test qw(Blog);
use ok "Blog::Controller::Articles";
use ok "Blog::Controller::Categories";
use ok "Blog::Controller::Comments";
use ok "Blog::Controller::Feeds";
use ok "Blog::Controller::Login";
use ok "Blog::Controller::Tags";
use ok "Blog::Controller::Users";

ok( request('/')->is_success, 'Requesting /');
ok( request('/articles/')->is_success, 'Requesting /articles/');
ok( request('/tags')->is_success);
ok( request('/tags/get_nav_box')->is_success);
ok( request('/tags/tag_list')->is_success);
ok( request('/login')->is_success, 'Request should succeed' );
ok( request('/login/nonce')->is_success, 'Request should succeed' );
ok( request('/users')->is_success, 'Request should succeed' );
