#!/usr/bin/perl
# Feeds.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Feeds;
use Angerwhale;

__PACKAGE__->config->{feeds} = Angerwhale->config->{feeds};

use base qw(Catalyst::Model::XML::Feed);

=head1 Angerwhale::Model::Feeds

Angerwhale model for obtaining sidebar RSS feeds.
  
See L<Catalyst::Model::XML::Feed> and L<Angerwhale>.

=cut

1;
