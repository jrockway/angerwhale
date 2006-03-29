package Blog::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Blog::Controller::Root - Root Controller for this Catalyst based application

=head1 SYNOPSIS

See L<Blog>.

=head1 DESCRIPTION

Root Controller for this Catalyst based application.

=head1 METHODS

=cut

=head2 default

=cut

sub auto : Private {
    my ($self, $c) = @_;
    
    $c->stash->{root} = Blog::Model::Filesystem->new($c);
}

sub blog : Path('') {
    my ( $self, $c ) = @_;
    
    $c->stash->{page}     = "home";
    $c->stash->{title}    = "Blog";
    $c->stash->{category} = "/";
    $c->forward("/categories/show_category");
}

sub default : Private {
    my ($self, $c) = @_;
    $c->response->redirect('/');
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
