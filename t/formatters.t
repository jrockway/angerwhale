#!/usr/bin/perl
# formatters.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use ok 'Blog::Format';

my @types = Blog::Format::types;
ok(@types > 0, 'do we have some formatters?');

my $txt = "This is some plain old text.\n\nThis is a new paragraph\n";
my $pod = <<'ENDPOD';

=head1 PLAIN OLD DOCUMENTATION

Plain old documentation is not just for documenting Perl
programs.  It can also be used to post to your blog.

=head1 ANOTHER HEADING

This test is good for POD processors, too.  This section of the test
looks like POD, but it's actually a heredoc.  Confusing!

ENDPOD
my $html = 'This <i>is</i> HTML. Hopefully this passes thru.';

# not a complete test, just want to see if things show up

my $formatted_html = Blog::Format::format($html, 'html');
my $text_html = Blog::Format::format_text($html, 'html');
is($formatted_html, $html, 'html passed through');
is($text_html, 'This is HTML. Hopefully this passes thru.');

my $formatted_txt  = Blog::Format::format($txt, 'txt');
my $text_txt  = Blog::Format::format_text($txt, 'txt');
ok($formatted_txt);
is($text_txt, $txt);

my $formatted_pod  = Blog::Format::format($pod, 'pod');
my $text_pod  = Blog::Format::format_text($pod, 'pod');
ok($formatted_pod);
ok($text_pod =~ /Confusing!$/);
