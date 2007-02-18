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

    my $ctime = creation_time($file);
    
    $self->metadata ( { get_attributes ( $file ), 
                        creation_time => $ctime ,
                        name          => $file->basename
                      } );
    $self->children ( [ $self->_children ] );
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

    File::Slurp::write_file(q{}.$self->file, $data);
    $self->next::method($data);
    
    return;
}

=head2 _children

[private] Get the children of this item.  See SUPER::children for public access.

=cut

sub _children {
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
    my @kids = $commentdir->children;
    
    @kids = 
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
      } @kids;

    return @kids;
}

1;

