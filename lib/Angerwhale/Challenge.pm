# Challenge.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Challenge;
use strict;
use warnings;
use Crypt::Random qw(makerandom);
use YAML::Syck;

use overload ( q{==} => "equals", q{""} => "raw_text" );

=head1 Angerwhale::Challenge

A cryptographic challenge for handling logins with PGP.

=head1 METHODS

=head2 new({uri => $c->base})

Create a new challenge, given a URI.  The current time and a 128-bit
random number are used for the time and the nonce, respectively.

=cut

sub new {
    my ( $class, $args ) = @_;
    my $self = {};

    my $random = makerandom( Size => 128, Strength => 0 );
    my $now = time();

    $self->{nonce} = "$random";
    $self->{uri}   = $args->{uri} || die "specify URI";
    $self->{date}  = "$now";

    bless $self, $class;
}

=head2 equals (=)

Compare two Challenges.

=cut

sub equals {
    my $self = shift;
    my $them = shift;

    return defined $them->{nonce}
      && defined $them->{uri}
      && defined $them->{date}
      && defined $self->{nonce}
      && defined $self->{uri}
      && defined $self->{date}
      && ( $self->{nonce} == $them->{nonce} )
      && ( $self->{uri} eq $them->{uri} )
      && ( $self->{date} eq $them->{date} );
}

=head2 raw_text (stringification)

Returns the challenge represented in string form, parsable
back into a Challenge by YAML.

=cut

sub raw_text {
    my $self = shift;
    return Dump($self);
}

1;
