#!/usr/bin/perl
# DateFormat.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Blog::DateFormat;
use strict;
use warnings;
use base qw(DateTime);
use utf8;

my @daynames = qw(日 月 火 水 木 金 土);

#sub new {
#    my $class = shift;
#    my $self = {seconds => $_[0] || time()};
#    
#    return bless $self, $class;
#}
#
#sub from_epoch {
#    return new(@_);
#}
#

sub _stringify {
    my $self = shift;
    
    my $year   = $self->year;
    my $month  = $self->month;
    my $day    = $self->day;
    my $wkday  = $self->day_of_week;
    
    my $hour   = $self->hour;
    my $minute = $self->minute; 
    $minute = "0$minute" if $minute < 10;
    
    my $ampm   = ($hour < 11) ? "am" : "pm";
    $hour %= 12;
    $hour =~ s/^0+$/12/;
    
    $wkday = $daynames[$wkday%7];
    
    return "$month-$day-$year ($wkday) $hour:$minute $ampm";
}

1;
