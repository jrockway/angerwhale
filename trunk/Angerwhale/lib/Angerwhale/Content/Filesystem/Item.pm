# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filesystem::Item;
use strict;
use warnings;
use Carp;
use File::Slurp;
use File::Attributes qw(get_attributes set_attribute);
use Path::Class ();
use Data::UUID;
use File::CreationTime qw(creation_time);
use Scalar::Defer;
use Class::C3;
use base 'Angerwhale::Content::Item';

__PACKAGE__->mk_accessors(qw/root file/);

=head1 NAME

Angerwhale::Content::Filesystem::Item - data and metadata stored on
disk representing an Angerwhale::Content::Item

=head1 SYNOPSIS

   my $base = dir(qw/path to some files/);
   my $root = $base;
   my $file = $base->file('an article');

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
L<Path::Class::Dir|Path::Class::Dir>.

=item file

Path to this file.  Must be a L<Path::Class::File>.

=back

=head2 store_attribute

Use File::Attributes to store metadata back to disk

=head2 store_data

Store data to disk

=cut

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);

    croak "need root" if !eval{ $self->root->isa( 'Path::Class::Dir')  };
    croak "need file" if !eval{ $self->file->isa( 'Path::Class::File') };
    
    my $file = q{}. $self->file; # stringify filename for IO()
    $self->data(read_file( $file )); 
    my %attributes = get_attributes ($file);
    
    # filter out empty attributes (BUG IN FILE::EXTATTR::listfattr)
    map { delete $attributes{$_} }
      grep { 1 if !defined $attributes{$_} }
        keys %attributes;

    $self->metadata ( { %attributes,
                        creation_time     => creation_time($file),
                        modification_time => (stat $file)[9],
                        name              => $self->file->basename,
                      } );
    
    # this needs the above metadata in order to work
    $self->metadata->{comment_count} = $self->_child_count;
    
    # set type from filename
    $self->{metadata}{type} ||= $self->{metadata}{name} =~ m{[.](\w+)$} ?
      $1 : 'text';
    
    return $self;
}

sub store_attribute {
    my $self  = shift;
    my $attr  = shift;
    my $value = shift;

    set_attribute(q{}.$self->file, $attr, $value); # store to disk
    $self->next::method($attr, $value);
    
    return;
}

sub store_data {
    my $self = shift;
    my $data = shift;

    File::Slurp::write_file(q{}.$self->file, $data);
    $self->next::method($data);
    
    return;
}

=head2 _children

[private] Get the children of this item.  See SUPER::children for public access.

=head2 children

Return (or set; INTERNAL USE ONLY) reference to the list of children.

=cut

sub children {
    my $self = shift;
    my $kids = shift;
    
    if (defined $kids) {
        return $self->{children} = $kids;
    }
    
    if (!$self->{children}) {
        $self->{children} = [$self->_children];
    }
    
    return $self->{children};
}

sub _get_commentdir {
    my $self = shift;
    
    my $commentdir;
    my $container = $self->file->dir;
    if ($container eq $self->root) {
        $commentdir = $container->subdir('.comments')->subdir($self->id);
    }
    else {
        $commentdir = $container->subdir($self->id);
    }    
    
    $commentdir->mkpath();    
    return $commentdir;
}

sub _children {
    my $self = shift;
    my $commentdir = $self->_get_commentdir();
    return 
      map {
          my $file = $_;
          Angerwhale::Content::Filesystem::Item->
              new({ root => $self->root,
                    base => $commentdir,
                    file => $file,
                  });
      } grep {
          # skip directories
          eval { $_->isa('Path::Class::File') }
      } $commentdir->children;
}

sub _child_count {
    my $self = shift;

    return scalar grep { eval { $_->isa('Path::Class::File') } }
      ($self->_get_commentdir->children);
}

1;

