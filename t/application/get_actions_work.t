#!/usr/bin/perl
# 01_get_actions.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 27;
use HTML::Tidy;
use Test::HTML::Tidy;
use YAML;
use Blog;

my $tidy = HTML::Tidy->new;
$tidy->ignore( type => TIDY_WARNING );

use Catalyst::Test qw(Blog);
use ok "Blog::Controller::Articles";
use ok "Blog::Controller::Categories";
use ok "Blog::Controller::Comments";
use ok "Blog::Controller::Feeds";
use ok "Blog::Controller::Login";
use ok "Blog::Controller::Tags";
use ok "Blog::Controller::Users";
use ok "Blog::Controller::ScheduledEvents";
use ok "Blog::Controller::Root";

my @html_urls = qw(/ /tags /tags/fake
	           /tags/tag_list /login /users);

my @urls = qw(/tags/tag_list /tags/do_tag);
 
foreach my $url (@html_urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    html_tidy_ok($tidy, $request->content, "$url HTML is valid");
}

foreach my $url (@urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
}

my $request = request('/login/nonce');
ok($request->is_success, 'requested a nonce OK');
my $nonce   = YAML::Load($request->content);
ok($nonce, 'nonce desearialized OK');
isa_ok($nonce, 'Blog::Challenge');
ok($nonce->{nonce}, 'nonce has a nonce');
