# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Articles;
use strict;
use warnings;
use Class::C3;
use Carp;
use base 'Catalyst::Model';

__PACKAGE__->mk_accessors(qw/storage_class storage_args source context filters/);

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    $self->storage_class('Filesystem') if !$self->storage_class;
    
    my $sclass = "Angerwhale::Content::ContentProvider::".$self->storage_class;
    eval "use $sclass";
    croak "can't load $sclass" if $@;
    
    my $s = $sclass->new($self->storage_args);
    
    # XXX;
    $self->filters([
                    sub { warn "Filtering ". $_[2]->id. "\n" },
                    sub { $_[2]->metadata->{filtered} = 1; },
                   ]);
    
    $self->source($s);
}

sub get_articles {
    my $self  = shift;
    return $self->_apply_filters($self->source->articles);
}

sub _apply_filters {
    my $self    = shift;
    my $article = shift;
    
    foreach my $filter (@{$self->filters||[]}) {
        # curry the filter
        my $f = sub { my $item = shift; $filter->($filter, $self->context, $item) };
        
        $article = $f->($article);

        my @children = @{$article->children()||[]};
        foreach my $child (@children) {
            $child = $f->($child);
        }
        $article->children([@children]);
    }
    
}

sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;
    $self->context($c);
    return $self;
}

1;

