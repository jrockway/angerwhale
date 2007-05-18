# DocBook.pm
# Copyright (c) 2007 Daniel Brosseau <dab@free.fr>

package Angerwhale::Format::DocBook;

use strict;
use warnings;
use XML::LibXSLT;
use XML::SAX::ParserFactory (); # loaded for simplicity;
use Angerwhale::Filter::ColorizeDbk;

my $xsltfile="/usr/share/sgml/docbook/stylesheet/xsl/nwalsh/xhtml/docbook.xsl";
my $debug=0;

=head1 Angerwhale::Format::DocBook

DocBook XML files as pretty HTML

=head1 METHODS

Standard methods implemented

=head2 new

=head2 can_format

Can format *.dbk|xml

=head2 types

Handles 'dbk' which is xml document

=head2 format

Returns the DocBook as XHTML 1.0

=cut

sub new {
    my $class = shift;
    my $self  = {};

    bless $self, $class;
}

sub can_format {
    my $self    = shift;
    my $request = shift;

    return 100 if ( $request =~ /dbk|xml/ );
    return 1;    # everything is text, so let this match a little
}

sub types {
    my $self = shift;
    return (
        {
            type        => 'xml',
            description => 'DocBook XML'
        }
    );
}

sub format {
    my $self = shift;
    my $text = shift;
    my $type = shift;

    # Compatible with Formater 'Encoding'
    $text = Encode::encode("utf-8", $text, 1);

    # 1 - Mark lang 
    # <programlisting lang="..."> to <programlisting lang="...">[lang=...] code [/lang]
    my $my_Handler = Angerwhale::Filter::ColorizeDbk->new($debug);
    $my_Handler->step('marklang');

    my $parsersax = XML::SAX::ParserFactory->parser(
	        Handler => $my_Handler,				 
	        );

    my @markedtext = eval{ $parsersax->parse_string($text)};
    if ($@) { die "\nDocument malformed : $@\n" ; } ;


    # 2 - Transform with xslt
    my $parser = XML::LibXML->new();
    my $xslt = XML::LibXSLT->new();

    my $source = eval {$parser->parse_string("@markedtext")};


    if ($@) { die "\nDocument malformed : $@\n" ; } ;

    my $style_doc = $parser->parse_file($xsltfile);
    my $stylesheet = 
      eval {
	$xslt->parse_stylesheet($style_doc);
      };

    warn "@_" if @_;



    # C'est ici que l'on peut ajouter le css, LANG ...
    # voir http://docbook.sourceforge.net/release/xsl/current/doc/html/index.html
    # et   http://www.sagehill.net/docbookxsl
    my $results = $stylesheet->transform($source, XML::LibXSLT::xpath_to_string('section.autolabel' => '1', 'chapter.autolabel' => '1', 'suppress.navigation' => '1'));


    my $format=2;

    my $string=$results->toString($format);

    # 3 - Colorize Code [lang=...] ... code ... [/lang]
    $my_Handler->step('colorize');

    my @colorized=$parsersax->parse_string($string);

    $string="@colorized";

    # 4 - filter
    # To adapt to angerwhale
    # delete <?xml version ...>, <html>,</html>,<head>,</head>,<body>,</body>
    $string =~ s/^.*<body>//s;
    $string =~ s/<\/body>.*<\/html>//s;


    # Compatible with Formater 'Encoding'
    $string = Encode::decode("utf-8", $string, 1);

    return "<div class=\"docbook\">" . $string . "</div>";
}

sub format_html {
    return _format( @_, 'format' );
}

1;

__END__

=head1 AUTHOR

Daniel Brosseau, dab@free.fr. Copyright 2007.

=head1 LICENSE

This is free software. You may use it or redistribute it under the same terms as Perl itself.

=cut
