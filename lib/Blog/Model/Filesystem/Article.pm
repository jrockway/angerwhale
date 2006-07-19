#!/usr/bin/perl
# Article.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Blog::Model::Filesystem::Article;
use strict;
use warnings;
use base qw(Blog::Model::Filesystem::Item);

sub categories {
    my $self = shift;
    my $base = $self->{base};
    my $name = $self->name;
    my $id   = $self->checksum; 
    

    my @categories = $self->{base_obj}->get_categories;
    my @paths = map {$base."/$_/$name"} @categories;

    my @result;
    my $i = 0;
    foreach my $path (@paths){
	eval {
	    my $obj = Blog::Model::Filesystem::Article->new({base   => $base,
							     base_obj => 
							     $self->{base_obj},
							     path   => $path});
	    my $myid = $obj->checksum;
	    push @result, $categories[$i] if $myid eq $id;
	};
	$i++;
    }
    
    return sort @result;
}

sub uri {
    my $self = shift;
    my $name = $self->name;
    return "articles/$name";
}


1;
