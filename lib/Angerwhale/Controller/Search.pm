package Angerwhale::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';
use KinoSearch::Searcher;
use KinoSearch::QueryParser::QueryParser;
use Angerwhale::Content::Filter::Index::Schema;

=head1 NAME

Angerwhale::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=cut

my $query_parser = KinoSearch::QueryParser::QueryParser->new(
        schema => Angerwhale::Content::Filter::Index::Schema->new,
);

sub index : Local {
    my ($self, $c) = @_;

    $c->{stash} = {results => []};

    my $query_string = $c->request->param('query');
    $c->detach( $c->view('JSON') ) unless defined $query_string;

    my $searcher;
    eval {
        $searcher = KinoSearch::Searcher->new(
                invindex => Angerwhale::Content::Filter::Index::Schema->open( $c->config->{plucene_index} ),
        );
    };

    $c->detach( $c->view('JSON') ) if $@;

    my $query = $query_parser->parse( $query_string );

    my $hits = $searcher->search(query => $query);
    $hits->seek(0, 10);

    my @results;
    while (my $hit = $hits->fetch_hit_hashref) {
        push @results, $hit;
    }

    my @results = sort { $a->{score} <=> $b->{score} } @results;

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
