# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

package Angerwhale::Content::Filter::Index;

use strict;
use warnings;
use Path::Class;
use KinoSearch::InvIndexer;
use KinoSearch::Analysis::PolyAnalyzer;

my $writer;

=head2 filter

Return a filter that will index the article.

=cut
  
sub filter {
    my $class = shift;
    my $app = shift;
    
    my $index_dir = dir($app->config->{plucene_index});
    $index_dir->rmtree;
    
    my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new(language => 'en'); #TODO: make this configurable
    
    $writer = KinoSearch::InvIndexer->new(
            invindex => $index_dir->stringify,
            analyzer => $analyzer,
            create   => 1,
    );

    $writer->spec_field(
            name  => 'title',
            boost => 3,
    );

    $writer->spec_field(name => $_)
        for qw/content author/;

    $writer->spec_field(
            name     => $_,
            indexed  => 0,
            analyzed => 0,
            stored   => 1,
    ) for qw/uri summary/;

    return sub {
        my $self    = shift;
        my $context = shift;
        my $item    = shift;

        my $content = $item->metadata->{formatted}->{text} || q{};

        my $doc = $writer->new_doc;
        $doc->set_value(content => $content);
        $doc->set_value(title   => $item->metadata->{ title   });
        $doc->set_value(uri     => $item->metadata->{ uri     });
        $doc->set_value(summary => $item->metadata->{ summary });
        $doc->set_value(author  => $item->metadata->{ author  }->fullname);

        $writer->add_doc($doc);

        return $item;
    };
}

1;
