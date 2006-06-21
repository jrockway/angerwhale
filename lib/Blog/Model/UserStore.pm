package Blog::Model::UserStore;

use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use YAML qw(LoadFile DumpFile);
use Blog::User;

=head1 NAME

Blog::Model::UserStore - Catalyst Model

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Model.

=head1 METHODS

=cut

# XXX: TODO: allow for storing duplicate keyids.  keyids don't have to
# be unique.

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new(@_);
    my $dir = $self->{users};
    
    mkdir $dir;
    die "no user store at $dir" if !-d $dir || !-w _;
    
    return $self;
}

sub create_user_by_real_id {
    my $self    = shift;
    my $real_id = shift;
    my $user    = Blog::User->new($real_id);
    
    $self->store_user($user);
    return $user;
}

sub get_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    
    my $dir = $self->{users};
    
    # create a user if one does not exist
    if( !-r "$dir/$nice_id"){
	my $real_id = pack('H*', $nice_id);
	return $self->create_user_by_real_id($real_id);
    }
    
    # load the YAML!
    my $user_obj = LoadFile("$dir/$nice_id");

    die "the object loaded from $dir/$nice_id isn't a Blog::User!"
      if !$user_obj->isa("Blog::User");

    $user_obj->thaw;

    die "inconsistient user data: looked up 0x$nice_id (from $dir/$nice_id)".
        "but got something else in the data file!" 
	  if $user_obj->nice_id ne $nice_id;
    
    return $user_obj;
}

sub refresh_user {
    my $self = shift;
    my $user = shift;

    $user->refresh;
    $self->store_user($user);
    $user->{refreshed} = 1;
}

sub get_user_by_real_id {
    my $self = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    
    return $self->get_user_by_nice_id($nice_id);
}

# stores by nice id
sub store_user {
    my $self = shift;
    my $user = shift;

    my $dir = $self->{users};
    my $uid = $user->nice_id;

    $user->freeze;
    DumpFile("$dir/$uid", $user);
    $user->thaw;
}

=head2 users

Returns a list of all the users (C<Blog::Users>s) the system knows about.

=cut

sub users {
    my $self = shift;
    my $dir = $self->{users};

    opendir(my $dirhandle, $dir) or die "Couldn't open $dir for reading";
    my @uids = readdir $dirhandle;
    my @users;
    foreach my $uid (@uids) {
	eval {
	    my $user = $self->get_user_by_nice_id($uid);
	    push @users, $user;
	};
    }
    return @users;

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
