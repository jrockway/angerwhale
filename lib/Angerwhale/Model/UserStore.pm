package Angerwhale::Model::UserStore;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';
use Path::Class qw(dir);

use Angerwhale::User;

__PACKAGE__->config ( class => 'Angerwhale::UserStore' );

sub prepare_arguments {
    my ($self, $app, $args) = @_;
    my $user_dir = dir($app->config->{base})->subdir('.users');
    $user_dir->mkpath;
    return { 
        directory => $user_dir,
        class     => Angerwhale::User->meta,
    };
}
