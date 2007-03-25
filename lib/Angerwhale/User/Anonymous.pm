# Anonymous.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::User::Anonymous;
use strict;
use warnings;
use base qw(Angerwhale::User);

=head1 NAME

Angerwhale::User::Anonymous - an anonymous uesr

=head1 SYNOPSIS

User that is un authenticated, like slashdot's Anonymous Coward.

=head1 METHODS

=head2 new

Create a new user

=head2 nice_id

0

=head2 id

0

=head2 fullname

Anonymous Coward

=head2 email

(nothing)

=cut

sub new {
    my $class = shift;
    my $self  = {};

    return bless $self, $class;
}

sub nice_id {
    return 0;
}

sub id {
    return 0;
}

sub fullname {
    return "Anonymous Coward";
}

sub email {
    return q{};
}

1;

