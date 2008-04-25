package Angerwhale::User::Anonymous;
use Moose;
extends 'Angerwhale::User';

has '+type'     => ( default => sub { 'anonymous' } );
has '+id'       => ( default => sub { 0 } );
has '+fullname' => ( default => sub { 'Anonymous Coward' } );
has '+email'    => ( default => sub { undef } );

1;

__END__

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

