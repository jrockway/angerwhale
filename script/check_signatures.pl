#!/usr/bin/env perl
# check_signatures.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Crypt::OpenPGP;
use HTTP::Request;
use LWP::UserAgent;
use YAML::Syck;

=head1 NAME

check_signatures.pl - get a YAML feed and check the signatures on it

=head1 SYNOPSIS

     check_signatures.pl http://blog.jrock.us/feeds/articles/yaml

=cut

my $source = $ARGV[0];
die "usage: $0 http://path/to/some/yaml" if !$source;
my @articles = get_yaml() or die "Couldn't get YAML feed.";

foreach my $article (@articles){
    if($article->{signed}){
	open(my $gpg, "|gpg --verify >/dev/null 2>&1");
	print {$gpg} $article->{raw}. "\n";
	close($gpg);
	print $article->{title}. ": ";
	print (((!$?) ? "ok" : "not ok"). "\n");
    }
}
exit 0;

sub get_yaml {
    my $request = HTTP::Request->new(GET => $source);
    my $ua = LWP::UserAgent->new;
    my $response = $ua->request($request);
    
    my $content = $response->content;
    return Load($content);
}
