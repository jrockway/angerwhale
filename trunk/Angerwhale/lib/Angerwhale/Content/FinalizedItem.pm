# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::FinalizedItem;
use strict;
use warnings;
use Carp;
use Quantum::Superpositions;
use Class::C3;
use base 'Class::Accessor';
use overload (
    q{<=>} => \&compare,
    q{cmp} => \&compare,

    # but still let other stuff work too
    fallback => "TRUE"
);

__PACKAGE__->mk_ro_accessors(qw/title name type author signed
                                summary text plain_text raw_text words
                                creation_time modification_time encoding
                               /);

=head1 NAME

Angerwhale::Content::FinalizedItem - read-only processed comment/article

=head1 DESCRIPTION

After filters are applied, it's a good idea to hide the internal
details of the article/comment from the rest of the program.  This
class wraps the article in a clean read-only interface (except for
comment-posting, etc.; you can write that way).

=cut

sub isa {
    my $self = shift;
    my $what = shift;
    
    return $what 
      if $what eq any(qw|Angerwhale::Content::Item
                         Angerwhale::Content::Article
                         Angerwhale::Content::Comment|);
    
    return $self->next::method(@_);
}

sub new {
    my $class = shift;
    my $item  = shift;
    croak "Need an item" unless eval{$item->isa('Angerwhale::Content::Item')};
    my $self  = {item => $item};
    
    bless $self => $class;
}

sub get_metadatum {
    my $self = shift;
    my $req  = shift;
    
    return $self->{item}{metadata}{$req};
}

sub get {
    my $self = shift;
    my $what = shift;
    
    # special cases
    if ($what eq 'text') {
        return $self->{item}{metadata}{formatted}{html};
    }
    elsif ($what eq 'plain_text'){
        return $self->{item}{metadata}{formatted}{text};
    }
    
    # general case
    return $self->get_metadatum($what);
}

sub mini {
    my $self = shift;
    my $mini = shift;
    if (defined $mini) {
        $self->{item}{metadata}{mini} = $mini;
    }
    return $self->{item}{metadata}{mini} ? 1 : 0;
}

sub id {
    my $self = shift;
    return $self->{item}{metadata}{guid};
}

sub compare {
    my $a = shift;
    my $b = shift;
    
    return $a->creation_time <=> $b->creation_time;
}

sub children {
    my $self = shift;
    return $self->{item}->children;
}

1;

