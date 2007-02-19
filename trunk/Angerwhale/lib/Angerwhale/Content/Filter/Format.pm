# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Content::Filter::Format;
use strict;
use warnings;
use Angerwhale::Format;

sub filter {
    return sub {
        my $self    = shift;
        my $context = shift;
        my $item    = shift;

        my $type = $item->metadata->{type};
        my $hash = $item->metadata->{checksum};
        my $key = "$type|$hash";

        # see if we have this item in cache already
        my $from_cache = $context->cache("formatted")->get($key);
        $item->metadata->{formatted} = $from_cache;
        return $item if defined $from_cache && ref $from_cache eq 'HASH';
        
        $context->log->debug("format cache miss on ". $item->id);
        # if not, we need to compute the HTML and plain text versions
        my $data = $item->data;
        $item->metadata->{formatted}{plain} = format_text($data, $type);
        $item->metadata->{formatted}{html}  = format_html($data, $type);
        
        # cache it
        $context->cache("formatted")->set($key, $item->metadata->{formatted});
        
        # done
        return $item;
    };
}

1;

