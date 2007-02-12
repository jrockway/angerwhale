#!/usr/bin/perl

use strict;
use warnings;
use URI;
use XML::Feed;
use YAML;
use IO::File;
use Pod::Usage;
use Path::Class;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Angerwhale;

GetOptions(
        'help|?'   => \my $help,
);

pod2usage(1) if $help || !$ARGV[0];

my $base_dir = dir(Angerwhale->config->{base});

my $feed = XML::Feed->parse( URI->new($ARGV[0]) )
    or die XML::Feed->errstr;

for my $entry ($feed->entries) {
    my $path = $base_dir;
    $path = $path->file($entry->title. '.html');
    print "Writing ". $entry->title. "\n";

    my $file = IO::File->new($path, 'w')
        or die "Unable to open $path for writing";

    $file->print($entry->content->body);
    $file->close;


    if (my $category = $entry->category) {
        my $category = dir($path->parent, $category);
        mkdir($category);
        symlink file($path), file($category, $path->basename());
    }
    
    my $atime = $entry->issued ? $entry->issued->epoch : time;
    if (!utime $atime, $atime, $path) {
        print "Could not set article creation time: $!\n";
    }
}

1;

=head1 

angerwhale_migrate.pl - migrate some other blog to Angerwhale

=head1 SYNOPSIS

angerwhale_create.pl [options] feed_url

 Options:
   -help          display this help

 Examples:
   angerwhale_migrate.pl http://example.com/feed.xml

=head1 DESCRIPTION

Migrate an existing XML feed to Angerwhale.

=head1 AUTHOR

Florian Ragwitz, C<rafl@debian.org>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
