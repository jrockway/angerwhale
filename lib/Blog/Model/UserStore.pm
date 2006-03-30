package Blog::Model::UserStore;

use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use YAML qw(LoadFile DumpFile);
use Blog::User;

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new(@_);
    my $dir = $self->{users};
    
    mkdir $dir;
    die "no users dir $dir" if !-d $dir || !-w _;
    
    return $self;
}

sub create_user_by_id {
    my $self = shift;
    my $id = shift;
    my $user = Blog::User->new($id);

    $self->store_user($user);
    return $user;
}

# retrieves by real uid (but filename is based on "nice id")
sub get_user_by_id {
    my $self = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    my $dir = $self->{users};
    
    # create a user if one does not exist
    return $self->create_user_by_id($real_id) if !-e "$dir/$nice_id";
    
    # load the YAML!
    my $user_obj = LoadFile("$dir/$nice_id");
    die "inconsistient data!" if $user_obj->id ne $nice_id;
    
    return $user_obj;
}

# stores by nice id
sub store_user {
    my $self = shift;
    my $user = shift;

    my $dir = $self->{users};
    my $uid = $user->id;
    
    DumpFile("$dir/$uid", $user);
}

=head1 NAME

Blog::Model::UserStore - Catalyst Model

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
