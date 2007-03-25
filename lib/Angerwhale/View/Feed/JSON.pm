# JSON.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
package Angerwhale::View::Feed::JSON;

use strict;
use warnings;
use base qw(Angerwhale::View::Feed Catalyst::View);
use JSON;

sub process {
    my ( $self, $c ) = @_;
    my @items = $self->prepare_items($c);

    my $stash = $c->stash;
    $c->res->content_type('application/json');
    $c->res->body(objToJson([@items]));
}

1;
__END__

=head1 NAME

Angerwhale::View::Feed::JSON - Syndicated JSON

=head1 DESCRIPTION

Outputs articles as JSON

=head1 METHODS

=head2 process

Prepares items, and then dumps the result as JSON

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
