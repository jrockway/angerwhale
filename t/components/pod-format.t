#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use ok 'Angerwhale::Format::Pod';
my $pf = Angerwhale::Format::Pod->new;

=for foo

my $html = $pf->format(<<EOP); # specific case that has caused me some sleep loss
 =pod
A long time ago, before I knew elisp, someone told me to never use
C<lexical-let>.  I've ignored their "advice" and have written this:

    lang:Common Lisp
    (require 'cl)
    
    (defun get-iterator-over-words-in (buffer)
      (lexical-let ((buf buffer)(pos 1))
   
EOP

use File::Slurp; write_file('/home/jon/t.html', $html);
=cut
