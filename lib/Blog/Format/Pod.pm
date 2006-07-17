#!/usr/bin/perl
# Pod.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
package Blog::Format::Pod;
use strict;
use warnings;
use Blog::Format::HTML;
use Pod::Simple::HTML;
use Pod::Simple::Text;

sub new {
    my $class = shift;
    my $self  = \my $scalar;
    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if($request =~ /pod/);
    return 0;
}

sub types {
    my $self = shift;
    return 
      ({type       => 'pod', 
       description => 'Perl POD (Plain Old Documentation)'});
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;
    
    my $pod_format = Pod::Simple::HTML->new;
    
    my $output;
    $pod_format->output_string( \$output );
    $pod_format->parse_string_document($text);
    
    my $html_format = Blog::Format::HTML->new;
    return $html_format->format($output, 'html');
}

sub format_text {
    my $self = shift;
    my $text = shift;
    my $type = shift;
    
    my $pod_format = Pod::Simple::Text->new;
    
    my $output;
    $pod_format->output_string( \$output );
    $pod_format->parse_string_document($text);
    
    my $text_format = Blog::Format::PlainText->new;
    return $text_format->format_text($output, 'text');
}

1;
