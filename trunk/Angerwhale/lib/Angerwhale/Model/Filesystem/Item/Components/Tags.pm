#!/usr/bin/perl
# Tags.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Tags;
use strict;
use warnings;
use File::Attributes qw(get_attribute set_attribute list_attributes);

=head1 SYNOPSIS

Mix this into Angerwhale::Model::Filesystem::Item to get tagging
support.

=head1 METHODS

=head2 set_tag(@tags)

Sets the following tags on the Item.  If a tag is already set,
its count is incremented

=cut

sub set_tag {
    my $self = shift;
    my @tags = @_;  
    map {s{(?:\s|[_;,!.])}{}g;} @tags; # destructive map
    
    foreach my $tag (@tags) {
	my $count = $self->tag_count($tag);
	$count = 0 if($count < 0);
	set_attribute($self->location, "tags.$tag", ++$count);
    }
    
    return $self->tags;
}

=head2 tag_count($tag)

Returns the number of times C<$tag> has been applied to this Item.

=cut


sub tag_count {
    my $self = shift;
    my $tag  = shift;
    return eval { get_attribute($self->location, "tags.$tag") };
}

=head2 tags

Returns a list of all tags that have been applied to this Item.

=cut

sub tags {
    my $self = shift;
    my $filename = $self->location;
    
    my @attributes;
    eval {
	@attributes = list_attributes($filename);
    };
    
    my %taglist; # hash to avoid duplicates (due to case)
    foreach my $attribute (@attributes){
	$attribute = lc $attribute;
	if($attribute =~ /^tags[.](.+)$/){
	    $taglist{$1} = 1;
	}
    }
    my @taglist;
    foreach my $tag (sort keys %taglist){
	# tags must be stored as utf8    
	my $copy = "$tag";
	utf8::decode($copy);
	push @taglist, $copy;
    }
    
    if(wantarray){
	return @taglist;
    }
    else {
	return join ';', @taglist;
    }
}

1; # magic true value
