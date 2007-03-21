# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Format;
use strict;
use warnings;
use Angerwhale::Format;

=head2 filter

Reads the body and adds a plain text and HTML formatted version to
metadata->formatted->[text|html].

=cut

sub filter {
    return sub {
        my $self    = shift;
        my $context = shift;
        my $item    = shift;

        my $type = $item->metadata->{type} || 'text';
        my $hash = $item->metadata->{checksum};
        my $key = "$type|$hash";

        # see if we have this item in cache already
        my $from_cache = $context->cache("formatted")->get($key);
        $item->metadata->{formatted} = $from_cache;
        return $item if defined $from_cache && ref $from_cache eq 'HASH';
        
        $context->log->debug("format cache miss on ". $item->id);
        # if not, we need to compute the HTML and plain text versions
        my $data = $item->data;
        $item->metadata->{formatted}{text} = Angerwhale::Format::format_text($data, $type);
        $item->metadata->{formatted}{html} = Angerwhale::Format::format_html($data, $type);
        
        # cache it
        $context->cache("formatted")->set($key, $item->metadata->{formatted});
        
        # done
        return $item;
    };
}

1;

