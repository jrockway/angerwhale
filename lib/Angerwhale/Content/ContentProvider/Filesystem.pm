# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::ContentProvider::Filesystem;
use strict;
use warnings;
use Angerwhale::Content::Filesystem::Item;
use Carp;
use File::Find;
use File::Spec;
use Quantum::Superpositions;

use base 'Angerwhale::Content::ContentProvider';
__PACKAGE__->mk_accessors(qw/root/);

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    croak "need root" if !$self->root;
    $self->root($self->root);
    return $self;
}

sub get_article {
    my $self = shift;
    my $name = shift;

    my $file = $self->root. "/$name";
    
    my $article = Angerwhale::Content::Filesystem::Item->
      new({ file => $file,
            root => $self->root });
    
    # determine what categories this article is in
    my $ino = (stat $article->file)[1]; # inode
    my @in;
  category:
    foreach my $c ($self->get_categories) {
        opendir my $dir, $self->root. "/$c"
          or die "failed to open ". $self->root. "/$c: $!";

      file:
        while( my $f = readdir $dir ){
            next if $f =~ /^[.][.]?$/;
            $f = $self->root. "/$f";
            next if !-e $f;
            
            my $_ino = (lstat $f)[1]; # inode
            if ($ino == $_ino) {
                push @in, $c;
                last file;
            }
        }
        closedir $dir;
    }
    
    $article->metadata->{categories} = [@in];
    return $article;
}

# returns ([files], [directories]) skipping .hidden_files
sub _read_dir {
    my $dir = shift;
    my (@files, @dirs);

    opendir my $dh, $dir or die "failed to open $dir: $!";
    while (my $file = readdir $dh) {
        next if $file =~ /^[._]/;
        my $path = "$dir/$file";
        if(!-d $path ){
            push @files, $file;
        }
        else {
            push @dirs, $file;
        }
    }
    closedir $dh;
    return (\@files, \@dirs);
}


sub get_articles {
    my $self = shift;
    my $dir  = shift || $self->root;
    
    my @files = @{((_read_dir($dir))[0])||{}}; # the beauty of perl
    my @articles;
    foreach my $file (@files) {
        push @articles, $self->get_article($file);
    }
    
    return @articles;
}

sub get_categories {
    my $self = shift;
    return @{((_read_dir($self->root))[1])||{}};
}

sub get_tags {
    my $self     = shift;
    my @articles = $self->get_articles;
    my @tags     = map { keys %{$_->{metadata}{tags}||{}} } @articles;
    my %found;
    @tags = grep { !$found{$_}++ } @tags;
    return sort @tags;
}

sub get_by_category {
    my $self = shift;
    my $category = shift;
    return $self->get_articles($self->root . "/$category");
}

sub get_by_tag {
    my $self = shift;
    my @tags = sort map { lc } @_;
    my @matching;
    
    my @articles = $self->get_articles();
  article:
    foreach my $article (@articles) {
        my @atags = sort keys %{$article->metadata->{tags}||{}};
        # (quantum computing)++
        push @matching, $article if all(@tags) eq any(@atags);
    }
    
    return @matching;
}

sub revision {
    my $self = shift;
    my $revision;
    find(sub {
             $revision += ( stat _ )[9]
               if !-d $File::Find::name && -e _;
         }, $self->root );
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
