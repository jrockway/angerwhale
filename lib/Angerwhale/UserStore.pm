package Angerwhale::UserStore;
use Moose;
use Angerwhale::User;
use Angerwhale::User::Anonymous;

extends 'MooseX::Storage::Directory';

sub get_user_by_id {
    my ($self, $id) = @_;
    return $self->lookup($id);
}

sub get_pgp_user {
    my ($self, $fpr) = @_;
    my $user = $self->get_user_by_id("pgp:$fpr") ||
      Angerwhale::User->new(
          type => 'pgp',
          id   => $fpr,
      );
    
    $self->store($user);
    return $user;
}

sub create_anon_user {
    my ($self, $fullname) = @_;
    my $user = Angerwhale::User::Anonymous->new(
        type     => 'anonymous',
        fullname => $fullname,
    );
    $self->store($user);
    return $user;
}

1;
