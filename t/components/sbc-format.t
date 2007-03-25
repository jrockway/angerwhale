#!/usr/bin/env perl
# sbc-format.t
# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

use Test::More tests => 4;
use ok 'Angerwhale::Format::SBC';
use Test::HTML::Tidy;
use Test::XML::Valid;
use strict;
use warnings;

my $sbc = Angerwhale::Format::SBC->new;
isa_ok( $sbc, 'Angerwhale::Format::SBC', 'created parser' );

my $input = do { local $/; <DATA> };
my $output = $sbc->format($input);

# make output tidier for tidy:
$output = <<"END";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en">
<head><title>test</title></head><body>$output</body></html>
END

my $tidy = HTML::Tidy->new( { config_file => 'tidy_config' } );
html_tidy_ok( $tidy, $output, 'html is tidy' );
xml_string_ok( $output, 'html is valid xml' );

__DATA__
*foo* /bar/

{http://www.example.org/foo.jpg image}

# one
# two
# three

[
\[...\] the three great virtues of a programmer:
- laziness,
- impatience and
- hubris.
] Larry Wall
