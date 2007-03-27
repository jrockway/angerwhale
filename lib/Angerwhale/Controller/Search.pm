package Angerwhale::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Plucene::Index::Reader;
use Plucene::Search::IndexSearcher;
use Plucene::QueryParser;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Search::HitCollector;

use Path::Class;
my $PLUCENE_INDEX = dir('', 'tmp', 'angerwhale', 'search_index');


=head1 NAME

Angerwhale::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=cut

my $parser   = Plucene::QueryParser->new({
        analyzer => Plucene::Analysis::SimpleAnalyzer->new,
        default  => 'content',
});

sub index : Local {
    my ($self, $c) = @_;

    $c->{stash} = {results => []};

    my $query_string = $c->request->param('query');
    $c->detach( $c->view('JSON') ) unless defined $query_string;

    my $searcher = Plucene::Search::IndexSearcher->
      new($c->config->{plucene_index});
    
    my @docs;
    my $hc = Plucene::Search::HitCollector->new(collect => sub {
            my ($self, $doc, $score) = @_;
            push @docs, [$doc, $score];
    });

    my $query = $parser->parse($query_string);

    eval {
        $searcher->search_hc($query => $hc);
    };

    if (my $error = $@) {
        die $@ unless $error =~ /Can't take log of 0/; #no documents indexed yet
    }

    @docs = map { $searcher->doc($_->[0]) } sort { $a->[1] <=> $b->[1] } @docs;

    $c->{stash} = {
        results => [map {
            my $doc = $_;
            
            +{
                map {
                    my $field = $doc->get($_);
                    $field ? ($field->name => $field->string) : ()
                } qw/title author uri summary/
            }
        } @docs],
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
