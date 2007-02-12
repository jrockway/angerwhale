package Angerwhale::Model::UserStore;

use strict;
use warnings;
use base qw(Catalyst::Model);
use NEXT;
use YAML::Syck qw(LoadFile DumpFile);
use Angerwhale::User;
use File::Slurp qw(read_file write_file);
use Carp;
use Crypt::OpenPGP::KeyRing;
use Crypt::OpenPGP::KeyServer;

=head1 NAME

Angerwhale::Model::UserStore - Manages Blog users.

=head1 SYNOPSIS

Keeps track of the blog's users.

    my $pgp_id = "cafebabe";
    my $user   = $c->model('UserStore')->get_user_by_nice_id($pgp_id);
    print "$pgp_id is ". $user->fullname;

See also L<Angerwhale::User|Angerwhale::User>.  Note that users are cached; they
are refreshed from the keyserver according to the config's
C<update_interval> in seconds.  Defaults to one hour.

If a user exists, but a keyserver can't be contacted, the old data
will still be used.

=head1 CONFIGURATION

=head2 keyserver

The keyserver to fetch PGP keys from.  Defaults to C<stinkfoot.org>,
since other keyservers can't manage to properly store and retieve the
author's key.

=head2 update_interval

Try to update user info from C<keyserver> after this many
seconds. Defaults to 3600, one hour.

=cut

__PACKAGE__->mk_accessors(qw|update_interval keyserver|);

=head1 METHODS

=head2 new

Called by Catalyst to create and initialize userstore.

=cut

# XXX: TODO: allow for storing duplicate keyids.  keyids don't have to
# be unique.

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new(@_);
    my $dir = $self->{users} = $c->config->{base} . '/.users';

    # read the config, first from $self->whatever, then from
    # c->config->whatever, and finally fall back to some
    # clever defaults
    $self->update_interval( $c->config->{update_interval} || 3600 )
      if !$self->update_interval;
    $self->keyserver( $c->config->{keyserver} || "stinkfoot.org" )
      if !$self->keyserver;

    mkdir $dir;
    if ( !-d $dir || !-w _ ) {
        $c->log->fatal("no user store at $dir ($!)");
        die "no user store at $dir";
    }

    return $self;
}

=head2 create_user_by_real_id

=head2 create_user_by_nice_id

Creates a new user in the user store (by the OpenPGP keyid "cafebabe"
[nice] or the Crypt::OpenPGP representation of that number [real]).
Returns the C<Angerwhale::User> on success, exception on failure.

=cut

sub create_user_by_real_id {
    my $self    = shift;
    my $real_id = shift;
    my $nice_id = unpack( 'H*', $real_id );

    return $self->create_user_by_nice_id($nice_id);
}

sub create_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    return $self->get_user_by_nice_id($nice_id);
}

=head2 get_user_by_real_id

=head2 get_user_by_nice_id

Retrieves the user, creating it if necessary.

=cut

sub get_user_by_real_id {
    my $self    = shift;
    my $real_id = shift;
    my $nice_id = unpack( 'H*', $real_id );

    return $self->get_user_by_nice_id($nice_id);
}

sub get_user_by_nice_id {
    my $self    = shift;
    my $nice_id = shift;
    my $real_id = pack( 'H*', $nice_id );

    my $dir          = $self->{users};
    my $base         = "$dir/$nice_id";
    my $user         = {};
    my $last_updated = 0;

    $user->{nice_id} = $nice_id;
    eval { $user->{public_key}  = read_file("$base/key") };
    eval { $user->{fullname}    = read_file("$base/fullname") };
    eval { $user->{fingerprint} = read_file("$base/fingerprint") };
    eval { $user->{email}       = read_file("$base/email") };
    eval { $last_updated        = read_file("$base/last_updated") };
    bless $user, 'Angerwhale::User';
    $user->{keyserver} = $self->{keyserver};

    my $outdated = ( ( time() - $last_updated ) > $self->{update_interval} );
    eval { _user_ok($user); };

    if ( !$@ && !$outdated ) {

        # refreshed OK
        return $user;
    }

    # create a user if the data was bad
    # or it's time to update
    eval {
        delete $user->{public_key};
        delete $user->{fullname};
        delete $user->{fingerprint};
        delete $user->{email};
        $user->refresh;
        $self->store_user($user);
        _user_ok($user);
    };

    confess "Could not refresh or retrieve user 0x$nice_id!" if $@;
    confess "user isnta a user" if !$user->isa('Angerwhale::User');

    return $user;
}

sub _user_ok {
    my $user = shift;
    die "no name"        if !$user->fullname;
    die "no key"         if !$user->public_key;
    die "no email"       if !$user->email;
    die "no fingerprint" if !$user->key_fingerprint;
    return 1;
}

=head2 refresh_user

Refresh the user's details from the keyserver

=cut

sub refresh_user {
    my $self = shift;
    my $user = shift;

    $user->refresh;
    $self->store_user($user);
    $user->{refreshed} = 1;
}

=head2 store_user

Write the user's data to disk, so that attributes can be
changed and so that the blog will work if the keyserver goes
offline.

=cut

# stores by nice id
sub store_user {
    my $self = shift;
    my $user = shift;

    my $dir = $self->{users};
    my $uid = $user->nice_id;

    my $base = "$dir/$uid";
    mkdir $base                                      if !-d $base;
    confess "couldn't create userdir $base for $uid" if !-d $base;
    eval {
        write_file( "$base/key",          $user->public_key );
        write_file( "$base/fullname",     $user->fullname );
        write_file( "$base/fingerprint",  $user->key_fingerprint );
        write_file( "$base/email",        $user->email );
        write_file( "$base/last_updated", time() );
    };
    if ($@) {
        confess "Error writing user: $!";
    }

    return 1;
}

=head2 last_updated

Returns the time of the most recent refresh of all users.

=cut

sub last_updated {
    my $self = shift;
    my $user = shift;
    my $dir  = $self->{users};
    my $uid  = $user->nice_id;
    my $base = "$dir/$uid";

    my $updated;
    eval { $updated = read_file("$base/last_updated"); };
    return $updated;
}

=head2 users

Returns a list of all the users (C<Angerwhale::Users>s) the system knows
about.  The users are refreshed if they've expired.

=cut

sub users {
    my $self = shift;
    my $dir  = $self->{users};
    my @users;
    opendir( my $dirhandle, $dir ) or die "Couldn't open $dir for reading";
    while ( my $uid = readdir $dirhandle ) {
        next if $uid =~ /^[.][.]?$/;    # .. and . aren't users :)
        eval {
            my $user = $self->get_user_by_nice_id($uid);
            push @users, $user;
        };
    }
    return @users;

}

=head1 NAME

Angerwhale::Model::UserStore - Catalyst Model

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
