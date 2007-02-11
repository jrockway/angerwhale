#!/usr/bin/perl
# Feeds.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Feeds;
use strict;
use warnings;

__PACKAGE__->config->{feeds} = Angerwhale->config->{feeds};

use base qw(Catalyst::Model::XML::Feed);

=head1 Angerwhale::Model::Feeds

Angerwhale model for obtaining sidebar RSS feeds.
  
See L<Catalyst::Model::XML::Feed> and L<Angerwhale>.

=head1 METHODS

=head1 COMPONENT

=cut

sub COMPONENT {
    my $class = shift;
    my $app   = $_[0];
    my $args  = $_[1];
    
    $args->{feeds} = $app->config->{feeds};
    $class->NEXT::COMPONENT(@_);
}

1;
