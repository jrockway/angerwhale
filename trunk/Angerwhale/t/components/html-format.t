#!/usr/bin/perl
# html-format.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 10;
use ok 'Blog::Format::HTML';

my $html = Blog::Format::HTML->new;
ok($html, 'created parser OK');

my $input  = do { local $/; <DATA> };
my $output = $html->format_text($input);

like($output, qr/THIS IS SOME TEXT/m, 'h1 works');
like($output, qr/THIS IS A LEVEL 2 HEADING/m, 'h2 works');
unlike($output, qr/This is a document.  Isn't that wonderful?  This line is getting pretty long, I hope someone cuts me off./m, 'text is cut');
like($output, qr/[\d]/m, 'number link refs exist');
like($output, qr/[\d].*http:/m, 'the links themselves exist');
unlike($output, qr/<b>/, 'no bold');
unlike($output, qr/<i>/, 'no italic');
unlike($output, qr/<p>/, 'no p tags');

__DATA__
<h1>This is some <b>text</b></h1>
<p>This is a document.  Isn't that wonderful?  This line is getting pretty long, I hope someone cuts me off.
Yay.  This is a new line, but in the same paragraph.  What will happen?</p>
<h2>This is a level 2 heading</h2>
<p>This is a paragraph.  Yay.</p>
<h3>This is h3</h3>
<p>This is a paragraph.  Also yay.</p>
<p>This <i>is italic</i>.</p>
<img src="http://www.example.com/images/image.png"
     alt="An example image"/>
<p>This is a link <a href="http://www.google.com/">to Google</a>.</p>
<p>Here is a link to <a href="http://blog.jrock.us/">Jon's Blog</a>.  It's good for you.</p>
<h2>New section 2</h2>
<p>Text, text, text, text.  Blah blah blah blah.
Blah.  Blah.  Text, some stuff.  Lorem ipsum.  Paragraph text.</p>
