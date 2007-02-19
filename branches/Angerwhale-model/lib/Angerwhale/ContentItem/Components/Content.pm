#!/usr/bin/perl
# Content.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::Components::Content;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use Carp;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw|plain_text text|);

use utf8;    # for the elipsis later on
my $ELIPSIS = "\x{2026}";

=head1 Content

Mix this into a C<Angerwhale::ContentItem> to get support for content
in the entries.  You probably want that.

=head1 METHODS

=head2 checksum

MD5 hash of the content

=cut

sub checksum {
    my $self = shift;
    my $text = $self->raw_text;
    utf8::encode($text);
    return md5_hex($text);
}

=head2 summary

Returns the first ten words of the content.

=cut

sub summary {
    my $self    = shift;
    my $summary = $self->plain_text;
    return if !defined $summary;

    my $SPACE = q{ };

    my @words = split /\s+/, $summary;
    if ( @words > 10 ) {
        @words = @words[ 0 .. 9 ];
        $summary = join $SPACE, @words;
        $summary .= " $ELIPSIS";
    }

    return $summary;
}

=head2 raw_text

Returns unformatted text, stripped of any PGP headers, armour, etc.

=cut

sub raw_text {
    my $self     = shift;
    my $want_pgp = shift;
    my $text     = shift
      || scalar read_file( '' . $self->location, binmode => ':raw' );
    $text = ' ' if !$text;

    if ( !$want_pgp ) {
        my $data;
        eval { $data = $self->_signed_text($text); };
        $text = $data if !$@;
    }

    # XXX: bugbug in crypt::openpgp?
    $self->from_encoding( $text, $self->location );
    return $text;
}

=head2 text

Returns HTML-formated text

=cut


=head2 plain_text

Returns plain text version of the item

=cut


=head2 words

Returns a word count of the item

=cut

sub words {
    my $self = shift;
    my $text = $self->plain_text;

    my @words = split /\b/, $text;
    return scalar @words;
}

1;