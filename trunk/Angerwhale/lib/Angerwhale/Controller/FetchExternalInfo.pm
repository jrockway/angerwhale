package Angerwhale::Controller::FetchExternalInfo;

use strict;
use warnings;
use base 'Catalyst::Controller';
use XML::Feed;

sub sidebar_feeds : Private {
    my ($self, $c, @args) = @_;

    my $desired_feeds_ref = $c->config->{feeds};
    return unless ref $desired_feeds_ref eq 'ARRAY'; #not an array ref? bye.

    my @desired_feeds = @{$desired_feeds_ref};
    
    my @result;
    foreach my $desired (@desired_feeds){
	my $key = 'feed|'. $desired->{location};
	my $data;
	if(!($data = $c->cache->get($key))){
	    my $feed  = XML::Feed->parse(URI->new($desired->{location}));
	    if(!$feed){
		$c->log->warn("can't retrieve feed ". $desired->{title}. 
			      "from ". $desired->{location}. ": ".
			      XML::Feed->errstr);
		next;
	    }
	    my @entries = ($feed->entries); # 10.
	    @entries = map {{title => $_->title,
			       link  => $_->link }} @entries; 
	    
	    #map {utf8::encode($_->{title})} @entries;
	    $data = { title => $desired->{title},
		      entries  => [@entries] };
	    
	    $c->cache->set($key => $data);
	}
	push @result, $data;
    }
    
    return [@result];
}

1;
__END__

=head1 NAME

Angerwhale::Controller::FetchExternalInfo - Pull down RSS feeds, etc., for
the sidebar

=head1 METHODS

=head2 sidebar_feeds

Reads the config, get the feeds from cache (if possible), and returns
the list of data.

=cut
