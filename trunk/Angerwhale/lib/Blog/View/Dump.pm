#!/usr/bin/perl
# Dump.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Blog::View::Dump;

use base qw(Catalyst::View);

use strict;
use YAML;

sub process {
    my $self = shift;
    my $c    = shift;
    
    $c->response->content_type('text/plain');
    $c->response->body(YAML::Dump($c->stash));
    
    return;
}

1;
