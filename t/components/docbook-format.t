#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 5;
use ok 'Angerwhale::Format::DocBook';
use Test::XML::Valid;
use Test::HTML::Tidy;
use FindBin qw($Bin);
use Path::Class;
use File::Slurp qw(read_file);

# XXX: test number at the top assumes two test files
my $testdata = dir($Bin, '..', 'testdata', 'docbook');
my @files = $testdata->children;

my $tidy = HTML::Tidy->new( { config_file => 'tidy_config' } );
my $docbook = Angerwhale::Format::DocBook->new;
    
foreach my $file (@files) {
    my $text = read_file("$file");
    my $html = $docbook->format_html($text, 'docbook');
    html_tidy_ok( $tidy, $html, 'html is tidy' );
    xml_string_ok( $html, 'html is valid xml' );
}
