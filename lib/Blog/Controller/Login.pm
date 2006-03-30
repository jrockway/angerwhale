package Blog::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Blog::Controller::Login - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub login_page : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = "login.tt";
    
}

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->forward("login_page");
}


=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
