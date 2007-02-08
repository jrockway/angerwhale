#!/usr/bin/perl
# Metadata.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Metadata;
use strict;
use warnings;
require File::CreationTime;
use File::Attributes qw(get_attribute set_attribute);

=head1 SYNOPSIS

Mix this into Angerwhale::Model::Filesystem::Item to get basic
metadata support.

=head1 METHODS

=head2 title

Returns the title of the article.

Attribute: title.

=cut


sub title {
    my $self = shift;
    my $name;
    
    # use the title attribute if it exists
    eval {
	$name = get_attribute($self->location, 'title');
    };
    
    # otherwise the filename is more than adequate
    if(!$name){
	$name = $self->name;
	$name =~ s{[.]\w+$}{};
    }
    $self->from_encoding($name, $self->location);
    return $name;
}


=head2 mini

Returns true if the article is a "mini-article"

Attribute: mini.

=cut
sub mini {
    my $self = shift;

    # allow override (mostly for the controller to pass on information
    # to the view)
    my $set  = shift;
    if(defined $set){
	$self->{_is_mini} = $set;
    }
    return $self->{_is_mini} if defined $self->{_is_mini};
    
    # if not overriden, read the attribute
    my $mini = eval {get_attribute($self->location, 'mini')};
    return $mini ? 1 : 0;
}

=head2 creation_time

See L<File::CreationTime>.

=cut

sub creation_time {
    my $self = shift;
    my $ct = File::CreationTime::creation_time($self->location);
    return $ct;
}

=head2 modification_time

mtime

=cut

sub modification_time {
    my $self = shift;
    my $time = (stat($self->location))[9];
    return $time;
}

=head2 author

Returns the L<Angerwhale::User> object for the author of this item, or
L<Angerwhale::User::Anonymous> if there is none.

=cut

sub author {
    my $self = shift;
    $self->signed; # fix the author information
    
    my $id = eval{ get_attribute($self->location, 'author')};
    
    if(defined $id){
	my $user = $self->userstore->get_user_by_nice_id($id);
	return $user if $user;
    }
    
    return Angerwhale::User::Anonymous->new();
}

=head2 type

Returns the type (format) of this article, based on the file's
extension or the attribute if it exists.

Attribute: type.

=cut

sub type {
    my $self = shift;
    my $type = eval { get_attribute($self->location, 'type')};
    
    if(!$type){
	if($self->location =~ m{[.](\w+)$}){
	    $type = $1;
	}
    }
    
    if(!$type){
	$type = 'text';
    }
    
    return $type;
}

