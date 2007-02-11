#!/usr/bin/perl
# Format.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Format;
use strict;
use warnings;
use Carp;
use Module::Pluggable (
    search_path => ['Angerwhale::Format'],
    instantiate => 'new',
);

sub _format {
    my ( $text, $type, $what ) = @_;

    croak 'invalid arguments to _format' if !defined $text || !$type;

    my @choices;
    foreach my $plugin ( plugins() ) {
        if ( $plugin->can('can_format') && $plugin->can($what) ) {
            my $possibility = $plugin->can_format($type);
            push @choices, [ $plugin, $possibility ];
        }
    }

    # now sort the choices, and choose the highest
    @choices = sort { $b->[1] <=> $a->[1] } @choices;
    my $choice = $choices[0]->[0];

    return $choice->$what( $text, $type );
}

sub format {
    return format_html(@_);
}

sub format_html {
    return _format( @_, 'format' );
}

sub format_text {
    return _format( @_, 'format_text' );
}

sub types {
    my @types;
    foreach my $plugin ( plugins() ) {
        push @types, $plugin->types() if $plugin->can('types');
    }
    return @types;
}

1;

__END__

=head1 NAME

Angerwhale::Format - Dispatches formatting of posts/comments to sub-modules

=head1 SYNOPSIS

=head1 EXTENSIONS

A Angerwhale::Format extension is simple to write.  It needs the following routines:

=head2 new

Initialize the formatter.  Returns a blessed reference, or dies on failure.

=head2 can_format(type)

This method will be called with the "type" to format.  Return 0 if you
can't handle it, or a higher number based on how well you can format
the "type".  1 is the lowest, 100 is the highest.

=head2 format(text, type)

This method will be called if your module returned the highest value
for C<can_format>.  It is passed the text to format, and the type.  It
should return the text formatted as HTML.

Alternatively, you may return an L<Angerwhale::VirtualComment>.

=head2 format_text(text, type)

Like C<format>, but return plain text instead of HTML.  If format_html
or format returns a VirtualComment, this method should return the same
one.

=head2 format_html

Alias.

=head2 types

Returns a list of hashrefs, where each hashref consists of:

=over 4

=item type

The name of the type, i.e. the name that C<can_format> will accept.

=item description

The human-readable description of the type.

=back


