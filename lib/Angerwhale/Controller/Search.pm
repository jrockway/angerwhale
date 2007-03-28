package Angerwhale::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';
use KinoSearch::Searcher;
use KinoSearch::Analysis::PolyAnalyzer;

=head1 NAME

Angerwhale::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=cut

my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');

sub index : Local {
    my ($self, $c) = @_;

    $c->{stash} = {results => []};

    my $query_string = $c->request->param('query');
    $c->detach( $c->view('JSON') ) unless defined $query_string;

    my $searcher = KinoSearch::Searcher->new(
            invindex => $c->config->{plucene_index},
            analyzer => $analyzer,
    );
    
    my $query = KinoSearch::QueryParser::QueryParser->new(
            analyzer => $analyzer,
            fields   => [qw/title author content/],
    );

    my $hits = $searcher->search(query => $query);
    $hits->seek(0, 10);

    my @results;
    while (my $hit = $hits->fetch_hit) {
        my $doc = $hit->get_doc;

        push @results, {
            map { ($_ => $doc->get_value($_)) } qw/title author uri summary/
        };
    }

    $c->log->_dump(\@results);

    $c->{stash} = {
        results => \@results,
    };

    $c->detach( $c->view('JSON') );
}

=head1 AUTHOR

Florian Ragwitz

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
