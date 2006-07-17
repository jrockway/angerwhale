package Blog::Model::Filesystem;
use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use Carp;
use Blog::Model::Filesystem::Article;
use Crypt::OpenPGP;

sub new {
    my ($self, $c) = @_;
    $self = $self->NEXT::new(@_);
    
    $self->{context} = $c;
    $self->{base}    = $c->config->{base};

    my $base = $self->{base};
    # die if base isn't readable or isn't a directory
    die "$base is not a valid data directory"
      if (!-r $base || !-d $base);
    
    return $self;
}

sub get_article {
    my $self	 = shift;
    my $article	 = shift;
    my $base     = $self->{base};

    die "article name contains weird characters"
      if $article =~ m{/};

    die "no such article" if !-r "$base/$article" || -d "$base/$article";
    
    return Blog::Model::Filesystem::Article->new({path     => "$base/$article",
						  base     => $base,
						  base_obj => $self});
    
}

sub _ls {
    my $self = shift;
    my $base = shift;
    
    opendir my $dir, $base or die "cannot open $base: $!";
    
    my @articles;
    while(my $article = readdir $dir){
	my $entry = "$base/$article";
	next if $article =~ m{^[.]}; # hidden files are also ignored
	next if !-r $entry;
	next if -d $entry;

	#entry is acceptable
	my $article = Blog::Model::Filesystem::Article->
	  new({path     => $entry,
	       base     => $self->{base},
	       base_obj => $self});

	push @articles, $article;
	
    }
    closedir $dir;
    return @articles;
}

sub get_articles {
    my $self = shift;
    my $base = $self->{base};

    return _ls($self, $base);
}

sub get_categories {
    my $self = shift;
    my $base = $self->{base};

    my @categories;
    opendir my $dir, $base or die "cannot open $base: $!";
    while(my $file = readdir($dir)){
	my $filename = "$base/$file";
	next if $file =~ /^[.]/;
	
	push @categories, $file if (-d $filename && -r $filename);
    }
    return sort @categories;
}

sub get_tags {
    my $self = shift;
    my @articles = $self->get_articles;
    my @tags = map {$_->tags} @articles; 
    my %found;
    @tags = grep {!$found{$_}++} @tags;
    return sort @tags;
}

sub get_by_category {
    my $self = shift;
    my $category = shift;

    my $base = $self->{base};
    my $path = "$base/$category";
    die "No category $category" if !-d $path;

    return _ls($self, $path);
}

sub get_by_tag {
    my $self = shift;
    my @tags = map {lc} @_;
    my @matching;

    my @articles = $self->get_articles();
  article: 
    foreach my $article (@articles){
	my $tags = $article->tags();
	foreach my $asked_for (@tags){
	    next article if $tags !~ /(?:\A|;)$asked_for(?:\Z|;)/;
	}
	push @matching, $article;
    }
    
    return @matching;
}

1; ## end ::Filesystem

=head1 NAME

Blog::Model::Filesystem - Catalyst Model

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
