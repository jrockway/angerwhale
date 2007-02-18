# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::ContentProvider::Filesystem;
use strict;
use warnings;
use Angerwhale::Content::Filesystem::Item;
use Carp;

use base 'Angerwhale::Content::ContentProvider';
__PACKAGE__->mk_accessors(qw/root/);

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    croak "need root" if !eval{ $self->root->isa( 'Path::Class::Dir')  };
    return $self;
}

sub article {
    my $self    = shift;
    my $article = shift;

    my $file = $self->root->file($article);
    
    return Angerwhale::Content::Filesystem::Item->
      new({ file => $file,
            root => $self->root });
}

sub articles {
    my $self = shift;
    my @files = grep { eval{$_->isa('Path::Class::File')} } $self->root->children;
    
    my @articles;
    foreach my $article (@files) {
        push @articles, $self->article($article->basename);
    }
    
    return @articles;
}

1;

