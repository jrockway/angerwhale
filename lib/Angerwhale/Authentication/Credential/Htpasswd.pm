# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Authentication::Credential::Htpasswd;
use strict;
use warnings;

use Carp;
use Apache::Htpasswd;

use base 'Angerwhale::Authentication::Credential';
__PACKAGE__->mk_ro_accessors(qw/passwdFile/);

sub name   { 'htpasswd' }
sub fields { [ username => { type => 'text'     },
               password => { type => 'password' },
             ]};

sub new {
    my ($class, $args) = @_;
    my $self = $class->next::method($args);
    croak 'need a passwdfile in Authentication::Credential::Htpasswd config'
      unless $self->passwdFile;

    $self->{_htpasswd} = Apache::Htpasswd->new({passwdFile => $self->passwdFile,
                                                ReadOnly   => 1
                                               });
    
    return $self;
}

sub verify {
    my ($self, $args) = @_;
    my ($username, $password) = @{$args}{qw/username password/};

    croak 'need username' unless $username;
    croak 'need password' unless $password;

    my $htpasswd = $self->{_htpasswd};
    my $ok = $htpasswd->htCheckPassword($username, $password);
    
    my $verified = $username if $ok;
    return $self->next::method($verified);
}

1;
