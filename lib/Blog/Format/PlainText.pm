#!/usr/bin/perl
# PlainText.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Blog::Format::PlainText;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if($request =~ /te?xt/);
    return 0;
}

sub types {
    my $self = shift;
    return 
      ({type       => 'text', 
       description => 'Plain text'});
    
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;
        
    $text =~ s/&/&amp;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/</&lt;/g;

    return $text;
}

1;

__END__

