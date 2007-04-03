# Copyright (c) 2007 Florian Ragwitz <rafl@debian.org>

package Angerwhale::Content::Filter::Index::Schema::FieldSpec::UnAnalyzed;

use strict;
use warnings;
use base qw/KinoSearch::Schema::FieldSpec/;

sub indexed  { 0 }
sub analyzed { 0 }
sub stored   { 1 }

package Angerwhale::Content::Filter::Index::Schema::FieldSpec::Boosted;

use strict;
use warnings;
use base qw/KinoSearch::Schema::FieldSpec/;

sub boost { 3 }

package Angerwhale::Content::Filter::Index::Schema;

use strict;
use warnings;
use base qw/KinoSearch::Schema/;
use KinoSearch::Analysis::PolyAnalyzer;

our %FIELDS = (
        title => 'Angerwhale::Content::Filter::Index::Schema::FieldSpec::Boosted',
        content => 'KinoSearch::Schema::FieldSpec',
        author  => 'KinoSearch::Schema::FieldSpec',
        uri     => 'Angerwhale::Content::Filter::Index::Schema::FieldSpec::UnAnalyzed',
        summary => 'Angerwhale::Content::Filter::Index::Schema::FieldSpec::UnAnalyzed',
);

sub analyzer {
    return KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');
}

1;
