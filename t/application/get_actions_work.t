#!/usr/bin/env perl
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
use Angerwhale::Test;

local $SIG{__WARN__} = sub { };

my $tidy = HTML::Tidy->new( { config_file => 'tidy_config' } );

#$tidy->ignore( type => TIDY_WARNING );

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

my @xml_urls  = qw(/feeds/articles/xml /feeds/comments/xml);
my @yaml_urls = qw(/feeds/articles/yaml /feeds/comments/yaml);

my $mech = Angerwhale::Test->new;

foreach my $url (@html_urls) {
    $mech->get_ok("http://localhost$url", "$url is OK");

    my $content = $mech->content;
    xml_string_ok( $content, "$url is valid XML" );
    html_tidy_ok( $tidy, $content, "$url is valid XHTML" );
}

foreach my $url (@urls) {
    $mech->get_ok("http://localhost$url", "$url is OK");
}

do {
    $mech->get("http://localhost/tags/do_tag");
    is( $mech->content, "Log in to edit.", "can't tag" );
};

foreach my $url (@yaml_urls) {
    $mech->get_ok( "http://localhost$url", "request $url OK" );
  SKIP: {
        skip 'no content', 1 if !$mech->content;
        yaml_string_ok( $mech->content, 'YAML is OK' );
    }
}

SKIP: {
    skip q{Need an Atom DTD for this}, 4;
    foreach my $url (@xml_urls) {
        $mech->get_ok( "http://localhost$url", "request $url OK" );
        xml_string_ok( $mech->content, "$url is valid XML" );
    }
}

$mech->get_ok( 'http://localhost/login/nonce', 'requested a nonce OK' );
my $nonce = Load( $mech->content );
ok( $nonce, 'nonce desearialized OK' );
isa_ok( $nonce, 'Angerwhale::Challenge' );
ok( $nonce->{nonce}, 'nonce has a nonce' );
