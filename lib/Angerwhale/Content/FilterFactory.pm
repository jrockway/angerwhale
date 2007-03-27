#!perl

package Angerwhale::Content::FilterFactory;
use strict;
use warnings;
use Carp;

=head1 NAME

Angerwhale::Content::FilterFactory - load filters and return the filter subs

=head1 SYNOPSIS

This module loads the Article filters in Angerwhale::Content::Filter
and returns an initialized filter subroutine.

=head1 METHODS

=head2 new($appliction)

Create a new FilterFactory for Angerwhale application C<$application>.

=cut

sub new {
    my $class = shift;
    my $app   = shift;
    croak "need an app" unless $app;
    
    my $self  = { app => $app };
    bless $self => $class;
}

=head2 get_filters(@names)

Returns initialized filter subroutines for each class mentioned in
C<@names>.  The Angerwhale::Content::Filter:: part is tacked on to the 
beginning of anything you pass.

An exception will be thrown if the entry in C<@names> can't be loaded
or doesn't return a proper filter.

=cut

sub get_filters {
    my $self = shift;
    my @names = @_;
    my @result;
    foreach my $name (@names) {
        $name = "Angerwhale::Content::Filter::$name";
        eval "require $name" or
          croak "$name is not a valid filter";
        
        my $filter = $name->filter($self->{app});
        croak "Filter returned by $name->filter was not a coderef"
          unless ref $filter eq 'CODE';
        
        push @result, $filter;
    }
    
    return @result;
}

=head1 AUTHOR

Jonathan Rockway

=head1 TODO

=over 4

=item * 

Implement an available_filters method

=item *

allow "foo" instead of Angerwhale::Content::Filter::Foo

=back

=cut

1;
