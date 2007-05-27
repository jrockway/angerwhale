#!/usr/bin/env perl
# markdown-format.t

use Test::More tests => 5;
use ok 'Angerwhale::Format::PlainText';
use Test::HTML::Tidy;
use Test::XML::Valid;
use Angerwhale::Test::Tidy;
use strict;
use warnings;

my $plaintext = Angerwhale::Format::PlainText->new;
isa_ok( $plaintext, 'Angerwhale::Format::PlainText', 'created parser' );

my $input = do { local $/; <DATA> };
my $output = $plaintext->format($input);

# make output tidier for tidy:
$output = <<"END";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en">
<head><title>test</title></head><body>$output</body></html>
END

my $tidy = Angerwhale::Test::Tidy->tidy();
html_tidy_ok( $tidy, $output, 'html is tidy' );
xml_string_ok( $output, 'html is valid xml' );

like($output, 
     qr|<a href="http://www\.google\.com/">http://www\.google\.com/</a>.|,
     'link was made clickable');

__DATA__ 

This is some text.  This is some text.  It is time for some text.

Here is a new paragraph, with a link to http://www.google.com/.  Enjoy.

