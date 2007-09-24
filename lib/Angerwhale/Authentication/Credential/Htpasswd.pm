# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Authentication::Credential::Htpasswd;
use strict;
use warnings;

use base 'Angerwhale::Authentication::Credential';

sub name   { 'htpasswd' }
sub fields { [ username => { type => 'text'     },
               password => { type => 'password' },
             ]};


1;
