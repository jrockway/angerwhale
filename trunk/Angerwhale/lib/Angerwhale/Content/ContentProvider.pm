# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::ContentProvider;
use strict;
use warnings;
use base 'Class::Accessor::Fast';


=head1 NAME

Angerwhale::Content::ContentProvider - provides methods for getting content

=head1 SYNOPSIS

   my $provider = Angerwhale::Content::ContentProvider::Subclass->new;
   my @articles = $provider->articles();
   my $article  = $procider->article('foo article');

=head1 METHODS

=head2 new

Create an instance -- don't call this method.

=head2 articles

Returns all articles

=head2 article

Returns a named article

=cut

sub articles {return }
sub article  {return }

1;

