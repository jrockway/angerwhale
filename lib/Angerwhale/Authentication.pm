# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Authentication;
use strict;
use warnings;
use Carp;

use Module::Pluggable (
    search_path => ['Angerwhale::Authentication::Credential'],
    require => 1,
);

my %CREDENTIAL_MAP = map { $_->name => $_ } plugins();

=head1 NAME

Angerwhale::Authentication - interface to the variety of ways in which
users can authenticate themselves to angerwhale

=head1 SYNOPSIS

   my @credentials = Angerwhale::Authentication->credentials;
   my $credential = Angerwhale::Authentication->credential('htpasswd');
   
   $credential->verify(username => 'foo', password => 'bar')
   # returns "htpasswd:foo" or undef if foo's password isn't bar

TODO: best credential

=head1 DESCRIPTION

The details of authentication are handled by
Angerwhale::Authentication::* modules.  These know how to verify user
credentials.  See L<Angerwhale::Authentication::Htpasswd> for a simple
example of username/password verification.

This module provides some introspection of these verifier plugins.

=head1 TODO

=over 4 

=item *

The verifiers should be able to produce a fill-out form for the web
user to use.

=item *

This module should be able to accept a list of form params and attempt
to verify the user using the best match.  "username, password" would
be htpasswd, "claimed_uri" would be openid, "signed_data" would be PGP.

=item *

Other stuff.

=head1 CLASS METHODS

=head1 credentials

Returns a list of verification plugins that have been loaded successfully

=cut

sub credentials {
    my $class = shift;
    return keys %CREDENTIAL_MAP;
}

=head1 credential($name [, @args])

Gets an instance of the verifier that can verify credentials of type
C<$name>.  C<$name> should have been returned by C<credentials>, otherwise
this method will die.

C<@args> is the list of arguments to pass to the constructor of the
credential.

=cut

sub credential {
    my ($class, $name, @args) = @_;
    my $cred = $CREDENTIAL_MAP{$name} || croak "no credential '$name' loaded";
    $cred->new(@args);
}

1;
