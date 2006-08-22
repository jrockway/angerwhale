package Angerwhale::Controller::ScheduledEvents;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub clean_sessions : Private {
    my ($self, $c) = @_;
    
    my $count = 0;
    $count = $c->model('NonceStore')->clean_sessions;
    if($count){
	$c->log->info("Cleaned $count stale sessions");
    }
    
    $count = $c->model('NonceStore')->clean_nonces;
    if($count){
	$c->log->info("Cleaned $count abandoned session requests");
    }
    
}

sub default : Private {
    return;
}

1;
