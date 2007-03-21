#!/usr/bin/perl
# SidebarFeeds.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Controller::SidebarFeeds;
use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Angerwhale::Controller::SidebarFeeds - return sidebar feeds as JSON

=head1 METHODS

=head2 all

Returns the JSON of all feeds in the config file

    [[title
      name
      link
      entires
         [[title
           link]
          [title2
           ...]]
      ]
     [title2
      ...

=head2 end

Forward to the JSON view

=cut

sub all : Local {
    my ($self, $c) = @_;
    my $max_entries = $c->config->{max_feed_entries} || 10;
    my @names = $c->model('Feeds')->names();
    
    $c->{stash} = {};
    my @feeds; # processed feeds
    foreach my $name (@names){
        my $feed = $c->model('Feeds')->get($name) or next;
        my $feed_data = {name  => $name,
                         title => $feed->title,
                         link  => $feed->link  };
        
        my @entries;
        foreach my $entry ($feed->entries){
            my $entry_data = { title => $entry->title,
                               link  => $entry->link, };
            push @entries, $entry_data;
            last if scalar @entries >= $max_entries;
        }
        $feed_data->{entries} = [@entries];
        push @feeds, $feed_data;
    }
    $c->stash->{feeds} = [@feeds];
}

sub end : Private {
    my ($self, $c) = @_;
    $c->forward('View::JSON');
}


1;
