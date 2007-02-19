# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::FinalizedItem;
use strict;
use warnings;
use Carp;
use Quantum::Superpositions;
use base 'Class::Accessor';
use overload (
    q{<=>} => \&compare,
    q{cmp} => \&compare,

    # but still let other stuff work too
    fallback => "TRUE"
);

__PACKAGE__->mk_ro_accessors(qw/title name type author signed comment_count
                                checksum post_uri parent_uri uri path
                                summary text plain_text words
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

    return $what if (defined $self->{item}{comment} &&
                     $what eq 'Angerwhale::Content::Comment');
    
    return $what 
      if $what eq any(qw|Angerwhale::Content::Item
                         Angerwhale::Content::Article|);
    
    return $self->SUPER::isa($what, @_);
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
    return $self->{item}->id;
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

sub comments {
    my $self = shift;
    return @{$self->children||[]};
}

sub categories {
    my $self = shift;
    return @{$self->{item}{metadata}{categories}||[]};
}

sub add_comment {
    my $self = shift;
    return $self->{item}->add_comment(@_);
}

sub raw_text {
    my $self = shift;
    
    return $self->{item}->data;
}

sub tags {
    my $self = shift;
    my %tags = %{$self->{item}{metadata}{tags}||{}};
    return keys %tags;
}

sub tag_count {
    my $self = shift;
    no warnings 'uninitialized';
    return $self->{item}{metadata}{tags}{$_[1]} || 0;
}

1;

