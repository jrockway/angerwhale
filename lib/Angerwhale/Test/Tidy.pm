# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Test::Tidy;
use strict;
use warnings;
use HTML::Tidy;

=head1 NAME

Angerwhale::Test::Tidy - setup a tidy for use with Angerwhale tests

=head1 SYNOPSIS

   use Angerwhale::Test::Tidy;
   my $tidy = Angerwhale::Test::Tidy->new;

=head1 METHODS

=head2 tidy

Return a new tidy object with the settings we desire

=cut

sub tidy {
    my $class = shift;
    return HTML::Tidy->new({'char-encoding' => 'utf8'});
}

1;
