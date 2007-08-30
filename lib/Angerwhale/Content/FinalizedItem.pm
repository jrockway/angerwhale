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

__PACKAGE__->mk_ro_accessors(qw/title name type author signed signor
                                comment_count
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

=head1 METHODS

=cut

sub _item {
    my $self = shift;
    return $self->{item};
}

=head2 isa

Lies on ISA checks so that a Finalized item looks like a
C<Angerwhale::Content::Article> if it's an article, or looks like a
C<Angerwhale::Content::Comment> if it's a comment.

=cut

sub isa {
    my $self = shift;
    my $what = shift;

    return $what if (defined $self->_item->{comment} &&
                     $what eq 'Angerwhale::Content::Comment');
    
    return $what 
      if $what eq any(qw|Angerwhale::Content::Item
                         Angerwhale::Content::Article|);
    
    return $self->SUPER::isa($what, @_);
}

=head2 new($item)

Wraps $item (an C<Angerwhale::Content::Item>) to make it read-only.

=cut

sub new {
    my $class = shift;
    my $item  = shift;
    croak "Need an item" unless eval{$item->isa('Angerwhale::Content::Item')};
    my $self  = {item => $item};
    
    bless $self => $class;
}

=head2 get_metadatum($name)

Reads named metadatdum.

=cut

sub get_metadatum {
    my $self = shift;
    my $req  = shift;
    
    return $self->_item->{metadata}{$req};
}

=head2 get

Overriding L<Class::Accessor|Class::Accessor>'s version for a few
special cases.

Normal case: get named data via C<get_metadatum>.  Special case:
formatted body (html and text).

=cut

sub get {
    my $self = shift;
    my $what = shift;
    
    # special cases
    if ($what eq 'text') {
        return $self->_item->{metadata}{formatted}{html};
    }
    elsif ($what eq 'plain_text'){
        return $self->_item->{metadata}{formatted}{text};
    }
    
    # general case
    return $self->get_metadatum($what);
}

=head2 mini

Returns true if the article is a mini article.  Allows
you to set status also.

=cut

sub mini {
    my $self = shift;
    my $mini = shift;
    if (defined $mini) {
        $self->_item->{metadata}{mini} = $mini;
    }
    return $self->_item->{metadata}{mini} ? 1 : 0;
}

=head2 id

Returns the UUID of the item.

=cut

sub id {
    my $self = shift;
    return $self->_item->id;
}

=head2 compare

Compares two items, based on creation_time.

=cut

sub compare {
    my $a = shift;
    my $b = shift;

    # allow comparision against timestamps too
    ($a,$b) = map { eval { $_->creation_time } || 0 } ($a,$b);
    
    return $a <=> $b;
}

=head2 children

Returns arrayref of comments attached to this Item.

=cut

sub children {
    my $self = shift;
    return $self->_item->children(@_);
}

=head2 comments

(backcompat)

Returns array of comments attached to this item, or false if there are
no comments.

=cut

sub comments {
    my $self = shift;
    return @{$self->children||[]};
}

=head2 categories

Returns the list of categories this item is in.

=cut

sub categories {
    my $self = shift;
    return @{$self->_item->{metadata}{categories}||[]};
}

=head2 add_comment

Attach a comment to this item.

=cut

sub add_comment {
    my $self = shift;
    return $self->_item->add_comment(@_);
}

=head2 raw_text

Return raw unformatted data.

=cut

sub raw_text {
    my $self = shift;
    my $mod  = shift;
    return $self->_item->{metadata}{raw_text} || $self->_item->data
      if $mod;
    
    return $self->_item->data;
}

=head2 tags

Return list of tags.

=cut

sub tags {
    my $self = shift;
    my %tags = %{$self->_item->{metadata}{tags}||{}};
    return keys %tags;
}

=head2 tag_count

Returns number of tags this article/comment has.

=cut

sub tag_count {
    my $self = shift;
    no warnings 'uninitialized';
    return $self->_item->{metadata}{tags}{$_[1]} || 0;
}

=head2 add_tag(@tags)

Add a list of tags to the entry.

=cut

sub add_tag {
    my $self = shift;
    my @tags = @_;

    $self->_item->add_tag(@tags);
    return;
}

1;

