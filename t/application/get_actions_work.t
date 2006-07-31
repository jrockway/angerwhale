#!/usr/bin/perl
# 01_get_actions.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 44;
use HTML::Tidy;
use Test::HTML::Tidy;
use Test::XML::Valid;
use YAML;
use Blog;

my $tidy = HTML::Tidy->new({config_file => 'tidy_config'});
#$tidy->ignore( type => TIDY_WARNING );

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

my @html_urls = qw(/ /tags /tags/fake /feeds/
	           /tags/tag_list /login /users);

my @urls = qw(/tags/tag_list /tags/do_tag /feeds/comments/xml /feeds/articles/xml);

my @xml_urls = qw(/feeds/articles/xml /feeds/comments/xml);
my @yaml_urls = qw(/feeds/articles/yaml /feeds/comments/yaml); 

foreach my $url (@html_urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    xml_string_ok($request->content, "$url is valid XML");
    html_tidy_ok($tidy, $request->content, "$url is valid XHTML");
}

foreach my $url (@urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
}

foreach my $url (@yaml_urls) {
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    eval {
	Load($request->content);
    };
    ok(!$@, "YAML parsed OK");
}

foreach my $url (@xml_urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    xml_string_ok($request->content, "$url is valid XML");
}

my $request = request('/login/nonce');
ok($request->is_success, 'requested a nonce OK');
my $nonce   = YAML::Load($request->content);
ok($nonce, 'nonce desearialized OK');
isa_ok($nonce, 'Blog::Challenge');
ok($nonce->{nonce}, 'nonce has a nonce');
