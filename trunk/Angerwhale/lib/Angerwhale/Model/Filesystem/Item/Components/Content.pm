#!/usr/bin/perl
# Content.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Model::Filesystem::Item::Components::Content;
use strict;
use warnings;
use Angerwhale::Format;
use Digest::MD5 qw(md5_hex);
use File::Slurp;
__PACKAGE__->mk_ro_accessor('cache');

use utf8; # for the elipsis later on
my $ELIPSIS = '…';

sub new {
    my ($class, $self) = @_;
    bless $self => $class;
    croak "No cache provided" if(!$self->{cache});
}

sub checksum {
    my $self = shift;
    my $text = $self->raw_text;
    utf8::encode($text);
    return md5_hex($text);
}

sub summary {
    my $self = shift;
    my $summary = $self->plain_text;
    return if !defined $summary;
    
    my $SPACE = q{ };

    my @words = split /\s+/, $summary;
    if(@words > 10){
	@words = @words[0..9];
	$summary = join $SPACE, @words;
	$summary .= " $ELIPSIS";
    }
    
    return $summary;
}

# returns unformatted text, strips OpenPGP armour etc. if necessary
sub raw_text {
    my $self     = shift;
    my $want_pgp = shift;
    my $text     = shift || scalar read_file( ''.$self->location,
					      binmode => ':raw' );
    $text = ' ' if !$text;
    
    if(!$want_pgp){
	my $data;
	eval {
	    $data = $self->_signed_text($text);
	};
	$text = $data if !$@;
    }
    
    # XXX: bugbug in crypt::openpgp?
    $self->from_encoding($text, $self->location);
    return $text;
}

# returns HTML-formatted data
sub text {
    my $self = shift;
    my $text = $self->raw_text;

    my $key = "htmltext|".$self->type."|".$self->checksum;
    my $data;
    if( $data = $self->cache->get($key) ){
	$data = ${$data};
    }
    else {
	$data = Angerwhale::Format::format($text, $self->type); 
	$self->cache->set($key, \$data);
    }
    return $data;
}

# returns plain text formatted data
sub plain_text {
    my $self = shift;
    my $text = $self->raw_text;
    my $key = 'plaintext|'. $self->type. '|' .$self->checksum;
    
    my $data;
    if( $data = $self->cache->get($key) ){
	$data = ${$data};
    }
    else {
	$data = Angerwhale::Format::format_text($text, $self->type); 
	$self->cache->set($key, \$data);
    }
    
    return $data;
}

# returns a word count
sub words {
    my $self = shift;
    my $text = $self->plain_text;

    my @words = split /\b/, $text;
    return scalar @words;
}

1;
