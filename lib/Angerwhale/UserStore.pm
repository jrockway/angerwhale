package Angerwhale::UserStore;
use Moose;
use Angerwhale::User;

extends 'MooseX::Storage::Directory';

sub get_user_by_id {
    my ($self, $id) = @_;
    return $self->lookup($id);
}

sub get_pgp_user {
    my ($self, $fpr) = @_;
    my $user = Angerwhale::User->new(
        type => 'pgp',
        id   => $fpr,
    );

    $self->store($user);
    return $self->get_user_by_id($user->get_id);
}

1;
