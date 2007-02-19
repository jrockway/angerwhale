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

sub get_article {
    my $self    = shift;
    my $article = shift;

    my $file = $self->root->file($article);
    
    return Angerwhale::Content::Filesystem::Item->
      new({ file => $file,
            root => $self->root });
}

sub get_articles {
    my $self = shift;
    my $dir  = shift || $self->root;
    
    my @files = grep { eval{$_->isa('Path::Class::File')} } $dir->children;
    
    my @articles;
    foreach my $article (@files) {
        push @articles, $self->get_article($article->basename);
    }
    
    return @articles;
}

sub get_categories {
    my $self = shift;
    return 
      sort
        map { $_->{dirs}[-1] }
          grep { eval {$_->isa('Path::Class::Dir')} && $_ !~ /^[.]/ } 
            $self->root->children;
}

sub get_tags {
#    my $self     = shift;
#    my @articles = $self->get_articles;
#    my @tags     = map { $_->tags } @articles;
#    my %found;
#    @tags = grep { !$found{$_}++ } @tags;
#    return sort @tags;
    return qw/fake tags/;
}

sub get_by_category {
    my $self = shift;
    my $category = shift;
    return $self->get_articles($self->root->dir($category));
}

sub get_by_tag {
    return; # todo
}

sub revision {
    my $self = shift;
    my $revision;
    find(sub {
             $revision += ( stat($File::Find::name) )[9]
               if !-d $File::Find::name;
         },
         ( $self->root ));
    return $revision;
}

1;

__END__

=head1 NAME

Angerwhale::Content::ContentProvider::Filesystem - get content from a directory of articles

=head1 METHODS

See L<Angerwhale::Content::ContentProvider>.

=head2 new

=head2 get_articles

=head2 get_article

=head2 get_categories

=head2 get_tags

=head2 get_by_tag

=head2 get_by_category

=head2 get_by_date

=head2 revision
