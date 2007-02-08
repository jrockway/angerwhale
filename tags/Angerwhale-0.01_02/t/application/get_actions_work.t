#!/usr/bin/perl
# 01_get_actions.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 45;
use HTML::Tidy;
use Test::HTML::Tidy;
use Test::XML::Valid;
use YAML::Syck qw(Load);
use Test::YAML::Valid qw(-Syck);
use Angerwhale;

local $SIG{__WARN__} = sub {};

my $tidy = HTML::Tidy->new({config_file => 'tidy_config'});
#$tidy->ignore( type => TIDY_WARNING );

use Catalyst::Test qw(Angerwhale);
use ok q"Angerwhale::Controller::Articles";
use ok q"Angerwhale::Controller::Categories";
use ok q"Angerwhale::Controller::Comments";
use ok q"Angerwhale::Controller::Feeds";
use ok q"Angerwhale::Controller::Login";
use ok q"Angerwhale::Controller::Tags";
use ok q"Angerwhale::Controller::Users";
use ok q"Angerwhale::Controller::Root";

my @html_urls = qw(/ /tags /tags/fake /feeds/
	           /tags/tag_list /login /users);

my @urls = qw(/tags/tag_list /feeds/comments/xml /feeds/articles/xml);

my @xml_urls = qw(/feeds/articles/xml /feeds/comments/xml);
my @yaml_urls = qw(/feeds/articles/yaml /feeds/comments/yaml); 

foreach my $url (@html_urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    my $content = $request->content;
    xml_string_ok($content, "$url is valid XML");
    html_tidy_ok($tidy, $content, "$url is valid XHTML");
}

foreach my $url (@urls){
    my $request = request($url);
    ok($request->is_success, "request $url OK");
}

do {
    my $request = request("/tags/do_tag");
    is($request->content, "Log in to edit.", "can't tag");
};

foreach my $url (@yaml_urls) {
    my $request = request($url);
    ok($request->is_success, "request $url OK");
    yaml_string_ok($request->content, 'YAML is OK');
}

SKIP: {
    skip q{Need an Atom DTD for this}, 4;
    foreach my $url (@xml_urls){
	my $request = request($url);
	ok($request->is_success, "request $url OK");
	xml_string_ok($request->content, "$url is valid XML");
    }
}

my $request = request('/login/nonce');
ok($request->is_success, 'requested a nonce OK');
my $nonce   = Load($request->content);
ok($nonce, 'nonce desearialized OK');
isa_ok($nonce, 'Angerwhale::Challenge');
ok($nonce->{nonce}, 'nonce has a nonce');
