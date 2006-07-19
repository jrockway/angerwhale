package Blog::Model::UserStore;

use strict;
use warnings;
use base qw(Catalyst::Model);
use NEXT;
use YAML qw(LoadFile DumpFile);
use Blog::User;
use File::Slurp qw(read_file write_file);
use Carp;
use Crypt::OpenPGP::KeyRing;
use Crypt::OpenPGP::KeyServer;

=head1 NAME

Blog::Model::UserStore - Manages Blog users.

=head1 SYNOPSIS

Keeps track of the blog's users.

    my $pgp_id = "cafebabe";
    my $user   = $c->model('UserStore')->get_user_by_nice_id($pgp_id);
    print "$pgp_id is ". $user->fullname;

See also L<Blog::User|Blog::User>.  Note that users are cached; they
are refreshed from the keyserver according to the config's
C<update_interval> in seconds.  Defaults to one hour.

If a user exists, but a keyserver can't be contacted, the old data
will still be used.

=head1 METHODS

=head2 new

=head2 new_user

=cut

# XXX: TODO: allow for storing duplicate keyids.  keyids don't have to
# be unique.

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new(@_);
    my $dir = $self->{users} = $c->config->{base}. '/.users';

    my $update_interval = $c->config->{update_interval} || 3600;
    my $keyserver       = $c->config->{keyserver} || "stinkfoot.org";

    $self->{update_interval} = $update_interval;
    $self->{keyserver}       = $keyserver;
    
    mkdir $dir;
    if(!-d $dir || !-w _){
	$c->log->fatal("no user store at $dir");
	die "no user store at $dir";
    }
    
    return $self;
}

sub new_user {
    my ($self, $nice_id) = @_;
    my $user = {};
    die "specify id" if !$nice_id;

    $user->{nice_id} = $nice_id;
    $user = bless $user, 'Blog::User';    
    
    $user->_keyserver($self->{keyserver});
    $user->refresh;

    return $user;
}

=head2 create_user_by_real_id

=head2 create_user_by_nice_id

Creates a new user in the user store (by the OpenPGP keyid 0xcafebabe
[nice] or the Crypt::OpenPGP representation of that number [real]).
Returns the C<Blog::User> on success, exception on failure.

=cut

sub create_user_by_real_id {
    my $self    = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    
    return $self->create_user_by_nice_id($nice_id);
}

sub create_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    return $self->get_user_by_nice_id($nice_id);
}

sub get_user_by_real_id {
    my $self = shift;
    my $real_id = shift;
    my $nice_id = unpack('H*', $real_id);
    
    return $self->get_user_by_nice_id($nice_id);
}

###::: XXX refactor this!!!!! I am way too sleepy to be programming!
sub get_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    my $real_id = pack('H*', $nice_id);
    
    my $dir = $self->{users};
    my $base = "$dir/$nice_id";
    my $user = {};
    my $last_updated = 0;
    
    eval {
	$user->{public_key}  = read_file("$base/key")          or die;
	$user->{fullname}    = read_file("$base/fullname")     or die;
	$user->{fingerprint} = read_file("$base/fingerprint")  or die;
	$user->{email}       = read_file("$base/email")        or die;
	$last_updated        = read_file("$base/last_updated") or die;
    };
    
    my $outdated = ((time() - $last_updated) > $self->{update_interval});
    
    if(!$@ && !$outdated){
	# refreshed OK
	$user->{nice_id} = $nice_id;
	return bless $user, 'Blog::User';
    }

    # create a user if the data was bad
    # or it's time to update
    $user = eval {
	if($user->can('refresh') && $user->id){
	    delete $user->{key};
	    delete $user->{fullname};
	    delete $user->{fingerprint};
	    delete $user->{email};
	    $user->refresh;
	    return $user;
	}
    };
    
    if($@){
	eval {
	    $user = $self->new_user($nice_id);
	    $self->store_user($user);
	};
    }
    
    # couldn't create a new user for some reason, and cached
    # version is invalid
    if($@ || !($user->{fullname} && $user->{public_key} &&
	       $user->{fingerprint} && $user->{email})){
	die "User $nice_id is invalid and could not be refreshed: $@";
    }

    # user is OK (might not be refreshed, if the keyserver was down)
    die if !$user->isa('Blog::User');

    return $user;
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
	write_file("$base/fullname", $user->fullname);
	write_file("$base/fingerprint", $user->key_fingerprint);
	write_file("$base/email", $user->email);
	write_file("$base/last_updated", time());
    };
    if($@){
	die "Error writing user: $!";
    }
    
    return 1;
}

sub last_updated {
    my $self = shift;
    my $user = shift;
    my $dir  = $self->{users};
    my $uid  = $user->nice_id;
    my $base = "$dir/$uid";
    
    my $updated;
    eval {
	$updated = read_file("$base/last_updated");
    };
    return $updated;
}

=head2 users

Returns a list of all the users (C<Blog::Users>s) the system knows
about.  The users are refreshed if they've expired.

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

=head2 keyring

Retruns a Crypt::OpenPGP::Keyring of all the cached users.  The users
are refreshed if they need to be.

=cut

sub keyring {
    my $self    = shift;
    my @users   = $self->users;
    my $keyring = Crypt::OpenPGP::KeyRing->new;

    foreach my $user (@users){
	
    }

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
