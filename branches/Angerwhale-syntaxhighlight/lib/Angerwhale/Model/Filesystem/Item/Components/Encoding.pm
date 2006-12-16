#!/usr/bin/perl
# Encoding.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Encoding;

use Encode;
use File::Attributes::Recursive qw(get_attribute_recursively);
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw|encoding|);

sub _encoding {
    my $self     = shift;
    my $filename = shift;
    if($filename){
	$encoding = get_attribute_recursively($filename, $self->base, 'encoding');
	return $encoding if $encoding; # '0' isn't a valid encoding :)
    }
    return $self->encoding || 'utf8';

}

sub from_encoding {
    my $self = shift;
    my $encoding = $self->_encoding($_[1]);

    $_[0] = Encode::decode($encoding, $_[0], 1) unless utf8::is_utf8($_[0]);
}

sub to_encoding {
    
    my $self = shift;
    my $encoding = $self->_encoding($_[1]);

    $_[0] = Encode::encode($encoding, $_[0], 1);
}

=head1 METHODS

=head2 from_encoding($string, [$filename])

Converts octets (in-place) in $string from the encoding (C<<
$self->encoding >>) to perl characters.  If $filename is specified,
reads $filename's "encoding" attribute and uses that to decode
$string.  If $filename is specified but doesn't contain the "ecoding"
attribute, the value of C<< $self->encoding >> is used instead.

Throws an exception on error.

=head2 to_encoding($string, [$filename])

Opposite of from_encoding.  (Converts perl characters to octets,
in-place, according to encoding.)

=cut

1;
