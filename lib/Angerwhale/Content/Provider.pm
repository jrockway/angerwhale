# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Provider;
use strict;
use warnings;
use base 'Class::Accessor::Fast';


=head1 NAME

Angerwhale::Content::Provider - provides methods for getting content

=head1 SYNOPSIS

   my $provider = Angerwhale::Content::Provider::Subclass->new;
   my @articles = $provider->get_articles();
   my $article  = $provider->get_article('foo article');

=head1 METHODS

=head2 new

Create an instance -- don't call this method.

=head2 get_articles

Returns all articles

=head2 get_article

Returns a named article

=head2 get_categories

Returns a sorted list of the names of all categories.

=head2 get_tags

Returns a sorted list of all tags that have been used

=head2 get_by_tag

Returns a sorted list of all articles that have been tagged with a
certain tag.  Multiple tags are also OK.

=head2 get_by_category

Retruns an unsorted list of all articles in a category.

=head2 get_by_date

XXX: TODO

=head2 revision

This method returns a "revision number" for the entire blog.  It will
increase over time, and will remain the same if nothing inside the
blog directory changes.  The revision number will decrease if
an article is removed, so don't remove them without restarting
the application.  (Otherwise the cache will be stale.)

=cut

1;

