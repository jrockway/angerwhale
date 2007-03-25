# Test.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Test;
use strict;
use warnings;
use Directory::Scratch;
use File::Attributes qw(set_attribute);

=head1 NAME

Angerwhale::Test - Test Angerwhale

=head1 SYNOPSIS

   use Angerwhale::Test (description => 'test blog',
                         title       => 'test blog',);

   my $mech = Angerwhale::Test->new;
   my $tmp  = $mech->tmp;

   # post an article
   $tmp->touch('article1', "This is an article."); 
   $mech->get_ok('http://localhost/articles/article1');

   return;
   # article is cleaned up automatically

=head1 METHODS

Subclasses Test::WWW::Mechanize::Catalyst.

=head2 import

Import the module, setup config, create tmp basedir.

=head2 new

Create a new Mech object (etc.).

=head2 tmp

Return Directory::Scratch object representing temp dir.

=cut

my $tmp;
sub import {
    my $class = shift;
    my %config = @_;
    
    $tmp = Directory::Scratch->new(TEMPLATE => 'angerXXXXXXXXXX');
    $ENV{"ANGERWHALE_base"} = $tmp->base;
    $ENV{"ANGERWHALE_html"} = 1;
    foreach my $key (keys %config){
        $ENV{"ANGERWHALE_$key"} = $config{$key};
    }
    return $class;
}

sub new {
    require Test::WWW::Mechanize::Catalyst;
    Test::WWW::Mechanize::Catalyst->import(qw|Angerwhale|);
    our @ISA = ('Test::WWW::Mechanize::Catalyst');
    my $class = shift;
    return $class->NEXT::new(@_);
}

sub tmp {
    return $tmp;
}

=head2 article(\%args)

Post a new article.  Args are title, body, type ...

Optionally you can pass a string instead of args, in which case the
string will be the title and the body.

=cut

sub article {
    my $self = shift;
    my $args = shift;
    $args = {title => $args, body => $args} unless ref $args;
    
    my $file = $args->{title};
    $file =~ s/\//_/g;
    $self->tmp->touch($file, $args->{body});
    set_attribute($self->tmp->exists($file), 'type', $args->{type}||'text');
    set_attribute($self->tmp->exists($file), 'title', $args->{title});
}

1;
