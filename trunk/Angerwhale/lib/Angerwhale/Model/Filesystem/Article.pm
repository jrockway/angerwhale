#!/usr/bin/perl
# Article.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Model::Filesystem::Article;
use strict;
use warnings;
use base qw(Angerwhale::Model::Filesystem::Item);
use Class::C3;
use Carp;

=head1 Filesystem::Article

Represents a C<Filesystem::Item> that's an article (not a comment or
preview comment).

=head1 METHODS

=head2 new

Create an article, see C<Filesystem::Item::new> for details.

=head2 categories

Return a list of categories that the article is in.

=head2 uri

Return the URI of this article.

=cut

sub new {
    my ($class, $args) = @_;
    croak "Articles cannot have a parent" 
      if $args->{parent};
    
    shift->next::method(@_);
}

sub categories {
    my $self = shift;
    my $base = $self->base;
    my $name = $self->name;
    my $id   = $self->checksum; 
    
    my @categories = $self->filesystem->get_categories;
    my @paths = map {$base."/$_/$name"} @categories;

    my @result;
    my $i = 0;
    foreach my $path (@paths){
	eval {
	    my $obj = Angerwhale::Model::Filesystem::Article->
	      new({ %{$self},
		    base     => $base,
		    location => $path,
		  });
	    
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
