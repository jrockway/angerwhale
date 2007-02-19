#!/usr/bin/perl
# Atom.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
package Angerwhale::View::Feed::Atom;

use strict;
use base qw(Angerwhale::View::Feed Catalyst::View);
use XML::Atom::SimpleFeed;

=head1 NAME

Angerwhale::View::Feed::Atom - render Atom feed

=head1 METHODS

=head2 process

Standard process method.

XXX: list accepted stash args

=cut

sub process {
    my ( $self, $c ) = @_;
    my @header;
    my $feed = XML::Atom::SimpleFeed->new(
        title => $c->stash->{feed_title}
          || ( ( $c->config->{title} || 'Blog' ) . ' Atom Feed' ),
        id   => $c->request->base,
        link => { rel => "self", href => $c->request->uri },
        link => $c->request->base,
        subtitle => $c->config->{description} || 'Atom Feed',
        generator => {
            version => $c->config->{VERSION},
            name    => 'Angerwhale',
            uri     => 'http://www.jrock.us/'
        },
    );

    foreach my $item ( $self->prepare_items($c) ) {
        my @data;
        push @data, ( title => $item->{title} );

        delete $item->{author}->{email} if $item->{author}->{keyid} eq '0';
        push @data, ( author => $item->{author} );
        push @data, ( id     => 'urn:guid:' . $item->{guid} );
        push @data, ( link   => $item->{uri} );
        eval {
            foreach my $category ( @{ $item->{categories} } )
            {
                push @data,
                  (
                    category => {
                        term   => $category,
                        scheme => $c->uri_for('/categories/')
                    }
                  );
            }
        };

        # not sure if i want to do this yet
        #eval {
        #    foreach my $tag (keys %{$item->{tags}}){
        #
        #	push @data, (category =>
        #		     {term   => $tag,
        #		      scheme => $c->uri_for('/tags/')});
        #    }
        #};
        push @data, ( updated => $item->{modified} );
        push @data,
          (
            content => {
                type    => 'xhtml',
                content => $item->{xhtml}
            }
          );

        $feed->add_entry(@data);
    }

    $c->response->content_type('application/atom+xml');
    my $output = $feed->as_string;
    $c->response->body($output);
    return $output;
}

1;

__END__
