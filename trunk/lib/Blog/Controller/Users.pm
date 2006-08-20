package Blog::Controller::Users;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Blog::Controller::Users - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Provides a listing of users and information about those users.

=head1 METHODS

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    
    my @users = $c->model('UserStore')->users;

    foreach my $user (@users){
	$user->refresh;
    }
    $c->stash->{users} = [@users];
    $c->stash->{template} = "users.tt";
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
