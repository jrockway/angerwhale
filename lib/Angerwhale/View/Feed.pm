# Feed.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::View::Feed;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use YAML::Syck qw(Dump);    # for debugging

=head1 NAME

Angerwhale::View::Feed - Common class that abstracts a "feed" of some sort

=head1 DESCRIPTION

This class serializes C<Angerwhale::ContentItem>s, presumably to generate
an RSS or YAML feed.

Here's what this class knows how to deal with:

=over 

=item A single C<Item>

If we get a single article or comment, we get the tree of children,
flatten it, and return the result as an array of serialized items.

=item Multiple C<Article>s

If we get multiple articles, then we assume we're doing the main 'RSS
feed', and return a list of those articles serialized without
children.

=back

=head1 METHODS

=head2 prepare_items

Takes the stash and outputs an array of "items" that go in the feed.
It's then up to the subclass to turn that into something readable

=cut

sub prepare_items {
    my ( $self, $c ) = @_;
    my $item_ref = $c->stash->{items};
    my @result;

    # single item; one article with comments, or a comment with comments
    if ( blessed $item_ref
         && $item_ref->isa('Angerwhale::Content::Item') )
      {
          push @result, $self->serialize_item( $c, $item_ref, 'recursive' );
      }
    
    # multiple items (probably articles)
    elsif ( ref $item_ref eq 'ARRAY' ) {
        foreach my $item ( @{$item_ref} ) {
            push @result, $self->serialize_item( $c, $item );    # not recursive
        }
    }

    # i don't know what to do!
    else {

        # no articles?
        return;
    }

    return @result;
}

=head2 serialize_item($item, $recursive?)

Serialize $item by converting it into a hashref.  Normally
Articles/Comments are lazy loaded, but this forces everything
to be evaluated and added to a hashref.

Attributes in the retured hashref are: title, type, summary, signed,
xhtml, text, raw, guid, uri, date (Created), modified, tags,
C<categories> the article is in (if possible),  and an arrayref of
C<comments> (if $recursive).

TODO: make this automatic.

=cut

sub serialize_item {
    my ( $self, $c, $item, $recursive ) = @_;

    my $data;
    Carp::confess "invalid item passed to serialize_item" . Dump($item)
      if !blessed($item) || !$item->isa('Angerwhale::Content::Item');
    my $author = $item->author;
    my $key    = 'yaml|' . $item->checksum . '|' . $item->comment_count;

    $data = $c->cache->get($key);
    return $data if ($data);

    $data->{author} = {
        name  => $author->fullname,
        email => $author->email,
        keyid => $author->nice_id,
    };

    $data->{title}    = $item->title;
    $data->{type}     = $item->type;
    $data->{summary}  = $item->summary;
    $data->{signed}   = $item->signed ? 1 : 0;
    $data->{xhtml}    = $item->text;
    $data->{text}     = $item->plain_text;
    $data->{raw}      = $item->raw_text(1);
    $data->{guid}     = $item->id;
    $data->{uri}      = "" . $c->uri_for( "/" . $item->uri );
    $data->{date}     = time2str( $item->creation_time );
    $data->{modified} = time2str( $item->modification_time );
    $data->{tags}     = [
        map {
            { $_ => $item->tag_count($_) }
          } $item->tags
    ];
    $data->{categories} = [ $item->categories ] if $item->can('categories');

    $data->{comments} =
      [ map { $self->serialize_item( $c, $_, 1 ) } $item->comments ]
      if $recursive;

    $c->cache->set( $key, $data );

    return $data;
}

=head2 time2str

Format times as per Atom spec

=cut

sub time2str {
    my $localtime = shift;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) =
      gmtime($localtime);
    $year += 1900;
    $mon  += 1;

    $mday = "0$mday" if $mday < 10;
    $mon  = "0$mon"  if $mon < 10;
    $hour = "0$hour" if $hour < 10;
    $min  = "0$min"  if $min < 10;
    $sec  = "0$sec"  if $sec < 10;

    return "$year-$mon-${mday}T$hour:$min:${sec}Z";
}

=head1 AUTHOR

Jonathan Rockway

=cut

1;
