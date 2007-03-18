#!/usr/bin/perl
# Comments.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::ContentItem::Components::Comments;
use strict;
use warnings;
use File::Find;
use File::Attributes qw(get_attribute set_attribute);

=head1 SYNOPSIS

Mix this into Angerwhale::ContentItem to get commenting
support.

=head1 METHODS

=head2 _path_to_top

Returns a list of comment IDs that this comment is a child of (in
order).

=cut

sub _path_to_top {
    my $self   = shift;
    my $parent = $self->parent;

    my @path;
    if ($parent) {
        @path = $parent->_path_to_top();
    }

    push @path, $self->id;
    return @path;
}

=head2 path

Like C<_path_to_top>, but joined with C</>s.

=cut

sub path {
    my $self = shift;
    return join '/', $self->_path_to_top;
}

=head2 _comment_dir

Returns the location where comments attached to this Item should be
stored.

=cut

sub _comment_dir {
    my $self = shift;
    my $base = $self->base . "/.comments/";

    return $base . join '/', $self->_path_to_top;
}

=head2 comment_count

Returns the number of comments attached to this Item.

=cut

sub comment_count {
    my $self        = shift;
    my $comment_dir = $self->_comment_dir;
    return 0 if !-e $comment_dir;    # return 0 quickly

    my $count = 0;
    find( sub { $count++ if $self->_comment_counter($File::Find::name) },
        $comment_dir );

    return $count;
}

sub _comment_counter {
    my $self     = shift;
    my $filename = shift;

    return if $filename =~ m{/[.][^/]+$};
    return if -d $filename;
    return if !-r $filename;

    return 1;
}

sub _create_comment_dir {
    my $self        = shift;
    my $comment_dir = $self->_comment_dir;

    if ( !-d $self->base ) {
        die "base " . $self->base . " does not exist!";
    }

    if ( !-e $self->base . "/.comments" ) {
        mkdir $self->base . "/.comments"
          or die "unable to create root commentdir: $!";
    }

    if ( !-d $comment_dir ) {
        mkdir $comment_dir
          or die "unable to create commentdir $comment_dir: $!";
    }

    return;
}

=head2 comments

Returns a list of all comments attached to this article (each item is
a L<Angerwhale::ContentItem::Comment> object).

=cut

sub comments {
    my $self        = shift;
    my $comment_dir = $self->_comment_dir;

    $self->_create_comment_dir;

    opendir my $dir, $comment_dir
      or die "unable to open commentdir $comment_dir: $!";

    my @comments;
    while ( my $file = readdir($dir) ) {
        my $filename = "$comment_dir/$file";
        next if -d $filename;
        next if $file =~ /^[.]/;

        my $comment = Angerwhale::ContentItem::Comment->new(
            {
                %{$self},
                base     => $self->base,
                location => $filename,
                parent   => $self,
            }
        );

        push @comments, $comment;
    }
    closedir $dir;

    return @comments;
}

=head2 add_comment($title, $body, $userid, $file_format)

Attaches a comment to this Item.

Arguments are:

=over 4

=item title

The title of this comment.  Any characters are allowed.

=item body

The main text of this comment, formatted in C<$file_format>.

=item userid

The (8-byte) "nice_id" of the comment poster.

=item format

The file format in which C<body> is encoded.  Examples: html, pod,
text, wiki.  (See L<Angerwhale::TODO::Formatter>.)

=back

=cut

sub add_comment {
    my $self  = shift;
    my $title = shift;
    my $body  = shift;
    my $user  = shift;
    my $type  = shift;

    die "no data" if ( !$title || !$body );

    $self->_create_comment_dir;
    my $comment_dir = $self->_comment_dir;
    die "no comment dir $comment_dir"
      if !-d $comment_dir;

    my $safe_title = $title;
    $safe_title =~ s{[^A-Za-z_]}{}g;    # kill anything unusual

    my $filename = "$comment_dir/$safe_title";
    while ( -e $filename ) {            # make names unique
        $filename .= " [" . int( rand(10000) ) . "]";
    }

    ## write the comment atomically ##
    my $tmpname = $filename;
    $tmpname =~ s{/([^/]+)$}{._tmp_.$1};

    # /foo/bar/comment1337abc! -> /foo/bar/._tmp_.comment1337abc!
    # maybe make a random filename instead?

    open my $comment, '>:raw', $tmpname
      or die "unable to open $filename: $!";
    eval {
        $self->to_encoding($body);
        print {$comment} "$body\n" or die "io error: $!";
        close $comment;
        rename( $tmpname => $filename )
          or die "Couldn't rename $tmpname to $filename: $!";
    };
    if ($@) {
        close $comment;
        unlink $tmpname;
        unlink $filename;    # partial rename !?
        die $@;              # propagate the message up
    }

    # set attributes: (TODO: atomic also)
    eval {

        # finally, attribute the comment to someone, if possible
        if ($user) {
            set_attribute( $filename, 'author', $user );
        }

        # and if the safe title and real title don't match, set
        # the title attribute

        $filename =~ m{/([^/]+)$};    # take into account the [##] that we added
        $safe_title = $1;

        if ( $title ne $safe_title ) {
            set_attribute( $filename, 'title', $title );
        }

        # finally, set the type
        if ( defined $type ) {
            set_attribute( $filename, 'type', $type );
        }
    };
    if ($@) {
        unlink $filename;
        die "Problems seting attributes: $@";
    }

    return;
}

=head2 post_uri

Returns the URI (relative to the application root) where replies to
this Item may be posted.

=cut

sub post_uri {
    my $self = shift;
    my $uri  = $self->uri;
    $uri =~ s{comments/}{comments/post/};
    return $uri;
}

1;    # magic true value
