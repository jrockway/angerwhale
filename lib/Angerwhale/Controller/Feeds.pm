package Angerwhale::Controller::Feeds;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Quantum::Superpositions;

=head1 NAME

Angerwhale::Controller::Feeds - Catalyst Controller

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 feeds

The main index of all available feeds

=cut

sub feeds : Path {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'feeds.tt';

    # for the sidebar
    $c->stash->{feed_categories} = [ $c->model('Articles')->get_categories ];
    $c->stash->{feed_tags}       = [ $c->model('Articles')->get_tags ];
}

=head2 article

Feed of an article and its comments

=cut

sub article : Local {
    my ( $self, $c, $article_name, $type ) = @_;

    # if an article name isn't specified, redirect them to the all-articles
    # feed
    if ( !defined $article_name ) {
        $c->response->redirect( $c->uri_for("/feeds/articles/$type") );
        return;
    }

    my $article =
      eval { return $c->model('Articles')->get_article($article_name) };

    $c->stash->{type} = $type;

    if ( $type ne 'yaml' && $type ne 'json' ) {

        # flatten comments
        my @todo = $article;
        my @items;
        while ( my $item = shift @todo ) {
            push @items, $item;
            my @comments = $item->comments;
            unshift @todo, @comments;    # depth first (sort of)
        }

        $c->stash->{items}      = [ sort @items ];
        $c->stash->{feed_title} = 'Comments on ' . $article->title;
    }
    else {
        $c->stash->{items} = $article;
    }
}

=head2 comments

Feed of recent comments.  How many comments to provide is specified
in C<< config->{max_feed_comments} >> (defaults to 30).

=cut

sub comments : Local {
    my ( $self, $c, $type, $unlimited ) = @_;
    my $max_comments = $c->config->{max_feed_comments} || 30;

    my @todo = $c->model('Articles')->get_articles;

    # todo contains articles first, but comments are added inside the loop

    my @candidates = _flatten_children(@todo);

    $c->stash->{feed_title} = $c->config->{title} . " Comment Feed"
      if $c->config->{title};

    $c->stash->{type} = $type;
    $c->stash->{items} =
      @candidates > $max_comments
      ? [ @candidates[ 0 .. $max_comments - 1 ] ]
      : \@candidates;
    return;
}

=head2 comment

Generates a feed of a single comment (and its children).

=cut

sub comment : Local {
    my ( $self, $c, $type, @path ) = @_;
    my $comment = $c->forward( '/comments/find_by_path', [@path] );
    $c->detach('/not_found') if !$comment;
    
    $c->stash->{type}       = $type;
    $c->stash->{items}      = [_flatten_children($comment)];
    $c->stash->{feed_title} = 'Replies to ' . $comment->title;
}

sub _flatten_children {
    my @todo = @_;
    my @candidates;    # store comments to show here, then sort at the end
    while ( my $item = shift @todo ) {
        push @candidates, $item
          if $item->isa('Angerwhale::Content::Comment');
        unshift @todo, ( $item->comments );    # depth first (sort of)
    }
    @candidates = reverse sort @candidates;
}

=head2 category

Feed of one category.

=cut

sub category : Local {
    my ( $self, $c, $category, $type ) = @_;
    
    $c->forward( '/categories/show_category', [$category||'/'] );

    if ( $c->config->{title} ) {
        $c->stash->{feed_title} = $c->config->{title};
        $c->stash->{feed_title} .= ": $category"
          if $category && $category ne q{/};
    }
    else {
        $c->stash->{feed_title} = "Articles in $category";
    }

    $c->stash->{items} = $c->stash->{articles};
    $c->stash->{type}  = $type;
    return;
}

=head2 articles

Feed of all articles.  The canonical "RSS feed".  Special case of
C<category>.

=cut

sub articles : Local {
    my ( $self, $c, $type ) = @_;
    $c->detach( 'category', [ q{}, $type ] );
}

=head2 tags

Feed of articles matching certain tags.  Tags are space separated in
the URI.

=cut

sub tags : Local {
    my ( $self, $c, $tag, $type ) = @_;
    $c->forward( '/tags/show_tagged_articles', [split /\s+/,$tag] );
    
    if ( $c->config->{title} ) {
        $c->stash->{feed_title} = $c->config->{title};
        $c->stash->{feed_title} .= " - Articles tagged with $tag"
          if $tag;
    }
    else {
        $c->stash->{feed_title} = "Articles tagged with $tag";
    }
    $c->stash->{type}  = $type;
    $c->stash->{items} = $c->stash->{articles};

    return;

}

=head2 feed_uri_for($uri, format = xml|yaml)

Given a location, returns the uri of that item's feed.

=cut

sub feed_uri_for : Private {
    my ( $self, $c, $location, $type ) = @_;

    $type = q{yaml} unless $type;    # default to YAML

    if ( $location eq '/' ) {
        return "/feeds/articles/$type";
    }
    elsif ( $location =~ m{/categories/([^/]+)} ) {
        return "/feeds/categories/$1/$type";
    }
    elsif ( $location =~ m{/articles/([^/]+)} ) {
        return "/feeds/article/$1/$type";
    }
    elsif ( $location =~ m{/tags/([^/]+)} ) {
        return "/feeds/tags/$1/$type";
    }
    return q{};    # no feed for that
}

=head2 end

Automatically forward to the right feed generator.

Requires that stash->{type} and stash->{items} are set.

=cut

sub end : Private {
    my ( $self, $c ) = @_;
    my $type = $c->stash->{type};

    # don't do anything if there's a body already
    return if $c->response->body; 
    
    undef $c->stash->{categories};

    if (!defined $type) {
        $c->detach('/end'); # delegate to TT
    }

    # they actually want a feed of some sort
    if ( $type eq any(qw|xml atom rss|) ) {
        $c->forward( 'View::Feed::Atom', 'process' );
    }
    elsif ( $type eq 'yaml' ) {
        $c->forward( 'View::Feed::YAML', 'process' );
    }
    elsif ( $type eq 'json' ) {
        $c->forward( 'View::Feed::JSON', 'process' );
    }
    else {
        # can't find invalid types
        $c->detach('/not_found'); 
    }
}

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
