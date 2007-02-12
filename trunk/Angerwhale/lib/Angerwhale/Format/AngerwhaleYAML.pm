#!/usr/bin/perl
# AngerwhaleYAML.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Format::AngerwhaleYAML;
use strict;
use warnings;
use Angerwhale::ContentItem::VirtualComment;
use LWP::UserAgent;
use YAML;

=head1 NAME

Angerwhale::Format::AngerwhaleYAML - format Angerwhale YAML feeds as comments

=head1 SYNOPSIS

Incorporate a comment (or article) and its children from another
Angerwhale instance into a discussion.

The text in the comment should be a single URL that is an Angerwhale
YAML feed.

TODO: Check to see that PGP signature of link matchs that of the
endpoint.

=head1 METHODS

Standard methods implemented

=head2 new

=head2 can_format

Can format *.angerwhale_yaml

=head2 types

Handles 'angerwhale_yaml', an Angerwhale YAML feed.  See
L<Angerwhale::Controller::Feeds> for details.

=head2 format

=head2 format_text

=cut

sub new {
    my $class = shift;
    my $self = \my $foo;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if defined $request && $request eq 'virtual_angerwhale_yaml';
}

sub types {
    my $self = shift;
    return (
        {
            type        => 'virtual_angerwhale_yaml',
            description => 'Link to a feed from another Angerwhale instance'
        }
    );
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    # XXX: disallow file:// URLs, probably
    $text =~ s/\s//g; # kill spaces
    
    my $feed;
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get($text);
    return "Error fetching content." unless $res->is_success;
    eval {
        $feed = Load($res->content);
    };
    return "Error parsing feed." if $@;

    my $article = _parse_article($feed);
    return $article;
}

sub _parse_article {
    my $article = shift;
    my $comments = $article->{comments} || [];
    my @comments;
    foreach my $comment (@$comments){
        push @comments, _parse_article($comment);
    } 
    my $result = Angerwhale::ContentItem::VirtualComment->
      new( { title    => $article->{title},
             raw_text => $article->{raw},
             type     => $article->{type},
             author   => $article->{author}->{keyid},
             comments => \@comments,
           } );
    
    return $result;
}

sub format_text {
    my $self = shift;
    return $self->format(@_);
}

1;
