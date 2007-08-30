# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filesystem::Item;
use strict;
use warnings;
use Carp;
use File::Slurp;
use File::Attributes qw(get_attributes set_attribute);
use File::Attributes::Recursive qw(get_attribute_recursively);
use File::Path qw(mkpath);
use File::Spec;
use File::Find;
use Data::UUID;
use File::CreationTime qw(creation_time);
use Class::C3;
use Encode;
use base 'Angerwhale::Content::Item';

__PACKAGE__->mk_accessors(qw/root file comment parent/);

=head1 NAME

Angerwhale::Content::Filesystem::Item - data and metadata stored on
disk representing an Angerwhale::Content::Item

=head1 SYNOPSIS

   my $base = '/path/to/some/files';
   my $root = $base;
   my $file = '/path/to/some/files/an article';

   my $item = Angerwhale::Content::Filesystem::Item->new
                 ({ root => $root,
                    base => $base,
                    file => $file,
                   });

   my $data = $item->data;
   my $meta = $item->metadata;
   my $kids = $item->children;

=head1 DESCRIPTION

Reads the basic content needed for an article or comment from the filesystem.

=head1 METHODS

=head2 new($hashref)

Create a new instance.  Hashref must contain:

=over 4

=item root

The root directory, where the "articles" live.  Must be a
directory.

=item file

Path to this file.  Must be a file.

=back

=head2 store_attribute

Use File::Attributes to store metadata back to disk

=head2 store_data

Store data to disk

=cut

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);

    croak "need full path to root" if !-d $self->root; 
    croak "need full path to file" if !-e $self->file;

    # fix up paths a bit
    $self->{root} =~ s{/+}{/}g;
    $self->{file} =~ s{/+}{/}g;
    $self->{root} =~ s{/+$}{};
    $self->{file} =~ s{/+$}{};
    
    my $file = $self->file;
    $self->data(scalar read_file( $file )); 
    
    # get parent attributes first (only encoding right now)
    my $encoding = get_attribute_recursively($file, $self->root, 'encoding');
    # now get the item-specific attributes
    my %attributes = get_attributes ($file);
    $encoding = $attributes{encoding} || $encoding || 'utf-8';
    $attributes{encoding} = $encoding;

    { # decode metadata now
        my %_attributes;
        while (my ($key, $value) = each %attributes) {
            $key   = Encode::decode($encoding, $key, 1);
            $value = Encode::decode($encoding, $value, 1);
            $_attributes{$key} = $value;
        }
        %attributes = %_attributes;
    }
    
    my (undef, undef, $basename) = File::Spec->splitpath($self->file);
    $self->metadata ( { %attributes,
                        creation_time     => creation_time($file),
                        modification_time => (stat $file)[9],
                        name              => Encode::decode($encoding, 
                                                            $basename, 1),
                      } );
    
    # this needs the above metadata in order to work
    $self->metadata->{comment_count} = $self->_child_count;

    # set the path to <parent path>/id
    $self->metadata->{path} = $self->id;
    if ($self->parent) {
        $self->metadata->{path} = $self->parent . '/'. $self->id;
    }
    
    # set type from filename
    $self->{metadata}{type} ||= $self->{metadata}{name} =~ m{[.](\w+)$} ?
      $1 : 'text';

    # is this a comment?
    $self->{metadata}->{comment} = defined $self->{comment} ? 1 : 0;

    # setup tags
    foreach my $t (grep {/tags[.]/} keys %{$self->{metadata}}) {
        my $count = delete $self->{metadata}{$t}; # cleanup
        $t =~ /tags[.](.+)/;
        $self->_add_tag($1, $count);
    }
    
    return $self;
}

sub store_attribute {
    my $self  = shift;
    my $attr  = shift;
    my $value = shift;

    set_attribute($self->file, $attr, $value); # store to disk
    $self->next::method($attr, $value);
    
    return;
}

sub store_data {
    my $self = shift;
    my $data = shift;

    File::Slurp::write_file($self->file, $data);
    $self->next::method($data);
    
    return;
}

sub _get_commentdir {
    my $self = shift;
    
    my $commentdir;
    my (undef, $container, undef) = File::Spec->splitpath($self->file);
    
    # XXX: this is why i was using Path::Class before :)
    $self->{root} =~ s{/+$}{};
    $container   =~ s{/+$}{}; # strip slashes for eq
    
    if ($container eq $self->root) {
        $commentdir = "$container/.comments/". $self->id;
    }
    else {
        $commentdir = "$container/". $self->id;
    }    
    
    mkpath($commentdir);
    return $commentdir;
}

=head2 _children

[private] Get the children of this item.  See SUPER::children for public access.

=cut

sub _children {
    my $self = shift;
    my $commentdir = $self->_get_commentdir();
    opendir my $dir, $commentdir or die "failed to open $commentdir: $!";
    my @result =
      map {
          my $file = "$commentdir/$_";
          Angerwhale::Content::Filesystem::Item->
              new({ root    => $self->root,
                    base    => $commentdir,
                    file    => $file,
                    comment => 1,
                    parent  => $self->metadata->{path},
                  });
      } grep {
          $_ !~ /^[.]/ &&           # skip hidden files
            !-d "$commentdir/$_"; # skip dirs
      } 
        readdir $dir;
    
    closedir $dir;
    return @result;
}

sub _child_count {
    my $self = shift;
    
    my $count = 0;
    find( sub { 
              $count++ if -f $File::Find::name && $_ !~ /^[.]/;
          }, $self->_get_commentdir );
    return $count;
}

=head2 add_tag(@tags)

Tag item with tags in C<@tags>.

=cut

sub add_tag {
    my $self = shift;
    my @tags = @_;

    foreach my $tag (@tags){
        $tag = lc $tag;

        # get count
        my $count = $self->metadata->{tags}{$tag} || 0;
        
        # store the new count to disk
        $self->store_attribute("tags.$tag", ++$count);
        
        # fix in core copy
        $self->metadata->{tags}{$tag} = $count;
          
        # delete extra metadat
        delete $self->metadata->{"tags.$tag"};
    }
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

    croak "no data to post" if ( !$title || !$body );
    
    my $comment_dir = $self->_get_commentdir;
    croak "no comment dir $comment_dir"
      if !-d $comment_dir;
    
    my $safe_title = $title;
    $safe_title =~ s{[^A-Za-z_]}{}g;    # kill anything unusual

    my $filename = $comment_dir. "/$safe_title";
    while ( -e $filename ) {            # make names unique
        $filename .= " [" . int( rand(10000) ) . "]";
    }

    ## write the comment atomically ##
    my $tmpname = $filename;
    $tmpname =~ s{/([^/]+)$}{._tmp_.$1};
    
    # /foo/bar/comment1337abc! -> /foo/bar/._tmp_.comment1337abc!
    # maybe make a random filename instead?

    open my $comment_fh, '>:raw', $tmpname
      or die "unable to open $filename: $!";
    eval {
        my $copy = "$body";
        utf8::encode($copy) if utf8::is_utf8($body);
        print {$comment_fh} "$copy\n" or die "io error: $!";
        close $comment_fh;
        rename( $tmpname => $filename )
          or die "Couldn't rename $tmpname to $filename: $!";
    };
    if ($@) {
        close $comment_fh;
        unlink $tmpname;
        unlink $filename;    # partial rename !?
        die $@;              # propagate the message up
    }

    # set attributes: (TODO: atomic also)
    my $comment;
    eval {
        $comment = Angerwhale::Content::Filesystem::Item->
            new({ root    => $self->root,
                  base    => $comment_dir,
                  file    => $filename,
                  comment => 1,
                  parent  => $self->metadata->{path},
                });
        
        # attribute the comment to someone, if possible
        if ($user) {
            $comment->store_attribute( 'author', $user );
        }
        
        # set title
        $comment->store_attribute( 'title', $title );
        
        # finally, set the type
        if ( defined $type ) {
            $comment->store_attribute( 'type', $type );
        }
    };
    if ($@) {
        unlink $filename;
        die "Problems seting attributes: $@";
    }
    
    return $comment;
}

1;

