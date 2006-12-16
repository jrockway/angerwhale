#!/usr/bin/perl
# Feeds.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Feeds;
use Angerwhale;

__PACKAGE__->config->{feeds} = Angerwhale->config->{feeds};

use base qw(Catalyst::Model::XML::Feed);
1;
