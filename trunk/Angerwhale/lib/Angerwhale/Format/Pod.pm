#!/usr/bin/perl
# Pod.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
package Angerwhale::Format::Pod;
use strict;
use warnings;
use IO::String;
use base qw(Pod::Xhtml Class::Accessor);
use Pod::Simple::Text;
use Angerwhale::Format::HTML;
use List::Util qw(min);
use Syntax::Highlight::Engine::Kate;
use Syntax::Highlight::Engine::Kate::All;

__PACKAGE__->mk_accessors('lang'); # what lang highlighter should use


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
    my $type = shift; # TODO: copy this into lang?

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
    
    if($lines[0] && $lines[0] =~ /\s*lang:(.+)\s*$/){
	
	if (!defined $1 || !$1 || $1 eq 'undef'){
	    $parser->lang(0) 
	}
	else { 
	    $parser->lang(ucfirst $1);
	}
	
	shift @lines;
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
    
    warn "using lang: ". $parser->lang;
    if($parser->lang){
	eval { 
	    my $hl = Syntax::Highlight::Engine::Kate->new
	      (language => 'Perl',
	       substitutions => {
				 "<"  => "&lt;",
				 ">"  => "&gt;",
				 "&"  => "&amp;",
				 q{'} => "&apos;",
				 q{"} => "&quot;",
				},
		format_table => {
				 Alert => ['<font color="#0000ff">', '</font>'],
				 BaseN => ['<font color="#007f00">', '</font>'],
				 BString => ['<font color="#c9a7ff">', '</font>'],
				 Char => ['<font color="#ff00ff">', '</font>'],
				 Comment => ['<font color="#7f7f7f"><i>', '</i></font>'],
				 DataType => ['<font color="#0000ff">', '</font>'],
				 DecVal => ['<font color="#00007f">', '</font>'],
				 Error => ['<font color="#ff0000"><b><i>', '</i></b></font>'],
				 Float => ['<font color="#00007f">', '</font>'],
				 Function => ['<font color="#007f00">', '</font>'],
				 IString => ['<font color="#ff0000">', ""],
				 Keyword => ['<b>', '</b>'],
				 Normal => ["", ""],
				 Operator => ['<font color="#ffa500">', '</font>'],
				 Others => ['<font color="#b03060">', '</font>'],
				 RegionMarker => ['<font color="#96b9ff"><i>', '</i></font>'],
				 Reserved => ['<font color="#9b30ff"><b>', '</b></font>'],
				 String => ['<font color="#ff0000">', '</font>'],
				 Variable => ['<font color="#0000ff"><b>', '</b></font>'],
				 Warning => ['<font color="#0000ff"><b><i>', '</b></i></font>'],
				},
	      );
	    
	    my $html   = $hl->highlightText($text);
	    $text = \$html;
	};
	if($@){
	  warn $@;
      }
    }
    
    # if vimcolor didn't work, just show the regular text
    $pod_para->text($text);
    $parser->parse_tree->append($pod_para);
}

1;
