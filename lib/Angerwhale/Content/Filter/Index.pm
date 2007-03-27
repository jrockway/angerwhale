# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

package Angerwhale::Content::Filter::Index;

use strict;
use warnings;
use Path::Class;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::Writer;
use Plucene::Analysis::SimpleAnalyzer;

my $writer;
my $index_dir = dir('', 'tmp', 'angerwhale', 'search_index');

=head2 filter

Return a filter that will index the article.

=cut

sub filter {
    $index_dir->rmtree;
    
    my $analyzer = Plucene::Analysis::SimpleAnalyzer->new;
    
    $writer = Plucene::Index::Writer->new(
            $index_dir->stringify,
            $analyzer,
            1,
    );

    return bless sub {
        my $self    = shift;
        my $context = shift;
        my $item    = shift;

        my $content = $item->metadata->{formatted}->{text} || q{};

        my $doc = Plucene::Document->new;
        $doc->add( Plucene::Document::Field->Text(content => $content) );
        $doc->add( Plucene::Document::Field->Text(title   => $item->metadata->{ title  }) );
        $doc->add( Plucene::Document::Field->Text(author  => $item->metadata->{ author }->fullname) );

        $doc->add( Plucene::Document::Field->UnIndexed(uri     => $item->metadata->{ uri     }) );
        $doc->add( Plucene::Document::Field->UnIndexed(summary => $item->metadata->{ summary }) );

        $writer->add_document($doc);
        $writer->_flush;

        return $item;
    };
}

1;
