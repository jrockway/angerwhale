# Time.pm
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Filter::Time;
use strict;
use warnings;
use Time::Duration qw(ago);
use utf8;

my @daynames = qw(日 月 火 水 木 金 土);

# Historical note.  I am an idiot for using DateTime for this!!!

=head1 Filter::Time

Format times (in seconds past the epochs) from TT

example:

   [% SET seconds = 123 %]
   [% seconds | time %]

=head1 METHODS

=head2 filter

Does the actual conversion at template runtime.

=cut

# converts seconds past the epoch, localtime, to a pretty string
sub filter {
    my ( $class, $time, $args, $format ) = @_;
    my @time  = localtime($time);

    my $formatted = eval {
        if($format){
            require POSIX;
            return POSIX::strftime($format, @time);
        }
    };
    return $formatted if defined $formatted;
      

    my $year  = $time[5] + 1900;
    my $month = $time[4] + 1;
    my $day   = $time[3];
    my $wkday = $time[6];

    my $hour   = $time[2];
    my $minute = $time[1];
    my $sec = $time[0];

    $minute = "0$minute" if $minute < 10;

    my $ampm = ( $hour < 11 ) ? "am" : "pm";
    $hour %= 12;
    $hour =~ s/^0+$/12/;

    $wkday = $daynames[ $wkday % 7 ];

    #my $ago = time() - $time;
    #if($ago < 86_400){
    #	return ago($ago);
    #}

    return "$year-$month-$day ($wkday) at $hour:$minute $ampm";
}

1;
