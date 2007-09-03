# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Config;
use strict;
use warnings;

use FindBin qw($Bin);
use Path::Class;
use Data::Visitor::Callback;

use base 'Class::Accessor::Fast';
use YAML::Syck;

sub new {
    my ($class, $config, $app) = @_;
    
    # load resource file
    my $res = LoadFile(_path_to($app, 'root', 'resources.yml'));

    # load config
    my $cfg = LoadFile(_path_to($app, 'angerwhale.yml'));

    # set config
    my $self = {%{$config||{}}, %$res, %$cfg};

    # fixup config
    my $v = Data::Visitor::Callback->new(
        value => sub { 
            if (defined $_ && /__path_to\((.+)\)__/) {
                my @data = split/,/,$1;
                $_ = _path_to($app, @data);
            }
        },
    );
    $v->visit($self); # expand macros

    return bless $self => $class;
}

sub _path_to {
    my $app  = shift;
    my @args = @_;
    if (eval { $app->can('path_to') }) {
        return $app->path_to(@args);
    }
    else {
        my $path = file($Bin, @args);
        my $i = 1;
        while (!-e $path && $i < 10) {
            $path = file($Bin, ('..') x $i++, @args);
        }
        die ((join '/',@args). ' was not found') if !-e $path;
        return $path;
    }
}

sub COMPONENT {
    my ($class, $app, $config) = @_;
    return $class->new($config, $app);
}

1;
