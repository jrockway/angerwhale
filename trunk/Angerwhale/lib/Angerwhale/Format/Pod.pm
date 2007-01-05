#!/usr/bin/perl
# Pod.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
package Angerwhale::Format::Pod;
use strict;
use warnings;
use IO::String;
use base 'Pod::Xhtml';
use Pod::Simple::Text;
use Angerwhale::Format::HTML;
use Text::VimColor;
use List::Util qw(min);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(TopLinks => 0,
				   MakeIndex => 0,
				   FragmentOnly => 1,
				   TopHeading => 3,
				  );
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
      ({type        => 'pod', 
	description => 'Perl POD (Plain Old Documentation)'});
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    $text = "=pod\n\n$text" unless $text =~ /\n=[a-z]+\s/;

    my $input  = IO::String->new($text);
    my $result = IO::String->new;
    
    $self->parse_from_filehandle($input, $result);
    
    return ${$result->string_ref};
}

sub format_text {
    my $self = shift;
    my $text = shift;
    my $type = shift;
    
    my $pod_format = Pod::Simple::Text->new;
    
    my $output;
    $pod_format->output_string( \$output );
    $text = "=pod\n\n$text" unless $text =~ /\n=[a-z]+\s/;
    $pod_format->parse_string_document($text);
    my $text_format = Angerwhale::Format::PlainText->new;
    return $text_format->format_text($output, 'text');
}

# HACK!
sub _handleSequence {
    my $self = shift;
    my $seq  = shift;
    
    if(ref $seq eq 'SCALAR'){
	return $$seq; # skip escaping step, since this is already HTML
    }
    else {
	return $self->SUPER::_handleSequence($seq);
    }
}

sub verbatim {
    my $parser    = shift;
    my $paragraph = shift;
    my $line_num  = shift;
    my $pod_para  = shift;
    my $text = $pod_para->text;

    # strip unnecessary leading spaces
    my $spaces = -1; # count of leading spaces
    my @lines = split /\n/, $text;

    my $lang = shift @lines;
    if($lang =~ /\s+lang:(\w+)\s*$/){
	$lang = $1;
    }
    else {
	unshift @lines, $lang;
    }
    
    # figure out how many that is
    for my $line (@lines){
	next if $line =~ /^\s*$/; # skip lines that are all spaces
	$line =~ /^(\s+)/;
	if($spaces == -1){
	    $spaces = length $1;
	}
	else {
	    $spaces = min($spaces, length $1);
	}
    }
    
    # strip 'em
    $text = "";
    for my $line (@lines){
	$text .= $line and next
	  if ($line =~ /^\s*$/);
	
	$text .= substr $line, $spaces;
	$text .= "\n";
    }
    $text =~ s/^\n+//; # strip unnecessary newlines
    $text =~ s/\n+$//; # strip unnecessary newlines
    
    if($lang){
	eval {
	    my $syntax = 
	      Text::VimColor->new(filetype => $lang, string => $text); 
	    my $html   = $syntax->html;
	    $text = \$html;
	};
    }
    # if vimcolor didn't work, just show the regular text
    $pod_para->text($text);
    $parser->parse_tree->append($pod_para);
}

1;
