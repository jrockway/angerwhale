package Blog::Model::UserStore;

use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use YAML qw(LoadFile DumpFile);
use Blog::User;
use File::Slurp qw(read_file write_file);
use Carp;

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
    my $dir = $self->{users} = $c->config->{base}. '/.users';

    mkdir $dir;
    if(!-d $dir || !-w _){
	$c->log->fatal("no user store at $dir");
	die "no user store at $dir";
    }
    return $self;
}

sub create_user_by_real_id {
    my $self    = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    my $user    = Blog::User->new($real_id);
    
    $self->store_user($user);
    return $user;
}

sub get_user_by_real_id {
    my $self = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    
    return $self->get_user_by_nice_id($nice_id);
}

sub get_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    
    my $dir = $self->{users};

    # read the user's public key
    my $base = "$dir/$nice_id";
    my $key;
    eval {read_file("$base/key")};
    my $real_id = pack('H*', $nice_id);
    
    # create a user if one does not exist
    if(!$key){
	return $self->create_user_by_real_id($real_id);
    }
    
    return Blog::User->new($real_id, $key);
}

sub refresh_user {
    my $self = shift;
    my $user = shift;

    $user->refresh;
    $self->store_user($user);
    $user->{refreshed} = 1;
}

# stores by nice id
sub store_user {
    my $self = shift;
    my $user = shift;

    my $dir = $self->{users};
    my $uid = $user->nice_id;

    my $base = "$dir/$uid";
    mkdir $base;
    die "couldn't create userdir $base for $uid" if !-d $base;
    eval {
	write_file("$base/key", $user->public_key);
	write_file("$base/name", $user->fullname);
	write_file("$base/fingerprint", $user->key_fingerprint);
    };
    if($@){
	die "Error writing user: $!";
    }
    
    return 1;
}

=head2 users

Returns a list of all the users (C<Blog::Users>s) the system knows about.

=cut

sub users {
    my $self = shift;
    my $dir  = $self->{users};
    my @users;
    opendir(my $dirhandle, $dir) or die "Couldn't open $dir for reading";
    while(my $uid = readdir $dirhandle){
	next if $uid =~ /^[.][.]?$/; # .. and . aren't users :)
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
