#!/usr/bin/perl
# PlainText.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Format::PlainText;
use strict;
use warnings;
use Text::Autoformat qw(autoformat break_TeX);

=head1 Angerwhale::Format::PlainText

Format plain text files as pretty HTML (and nicely-formated plain
text via Text::AutoFormat)

=head1 METHODS

Standard methods implemented

=head2 new

=head2 can_format

Can format *.txt and *.text.

=head2 types

Handles 'text' which is plain text

=head2 format

=head2 format_text

=cut

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if ( $request =~ /te?xt/ );
    return 1;    # everything is text, so let this match a little
}

sub types {
    my $self = shift;
    return (
        {
            type        => 'text',
            description => 'Plain text'
        }
    );

}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    $text =~ s/&/&amp;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/'/&apos;/g;
    $text =~ s/"/&quot;/g;

    my @paragraphs = split /\n+/m, $text;
    @paragraphs = grep { $_ !~ /^\s*$/ } @paragraphs;
    return join( ' ', map { "<p>$_</p>" } @paragraphs );
}

sub format_text {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    return autoformat( $text, { break => break_TeX, all => 1 } );
}

1;

__END__

