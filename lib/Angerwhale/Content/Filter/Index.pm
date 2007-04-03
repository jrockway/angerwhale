# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

package Angerwhale::Content::Filter::Index;

use strict;
use warnings;
use Path::Class;
use KinoSearch::InvIndexer;
use Angerwhale::Content::Filter::Index::Schema;

=head2 filter

Return a filter that will index the article.

=cut
  
sub filter {
    my $class = shift;
    my $app = shift;
    
    my $index_dir = dir($app->config->{plucene_index});
    $index_dir->rmtree;

    return sub {
        my $self    = shift;
        my $context = shift;
        my $item    = shift;

        my $writer = KinoSearch::InvIndexer->new(
                invindex => Angerwhale::Content::Filter::Index::Schema->clobber( $index_dir->stringify ),
        );
    
        my $content = $item->metadata->{formatted}->{text} || q{};

        $writer->add_doc({
                content => $content,
                title   => $item->metadata->{ title   },
                uri     => $item->metadata->{ uri     },
                summary => $item->metadata->{ summary },
                author  => $item->metadata->{ author  }->fullname,
        });

        $writer->finish;

        return $item;
    };
}

1;
