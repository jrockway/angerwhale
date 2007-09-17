package Angerwhale::UserStore;
use Moose;

extends 'MooseX::Storage::Directory';

sub get_user_by_id {
    my ($self, $id) = @_;
    return $self->lookup($id);
}

1;
