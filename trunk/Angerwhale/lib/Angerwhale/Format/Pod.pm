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
    $Text::VimColor::DEBUG = 1;
    my $syntax = Text::VimColor->new(filetype => 'perl', string => $text); 
    my $html   = $syntax->html;
    $pod_para->text(\$html);
    $parser->parse_tree->append($pod_para);
}

1;
