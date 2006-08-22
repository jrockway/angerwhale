package Angerwhale::View::Feed::YAML;

use strict;
use warnings;
use base qw(Angerwhale::View::Feed Catalyst::View);
use YAML;
use Scalar::Util qw(blessed);

# TODO: not *quite* what we want
sub process {
    my ($self, $c) = @_;
    my @items = $self->prepare_items($c);
    
    # all went well, so we're done
    $c->response->content_type('text/x-yaml; charset=utf-8');
    $c->response->body(Dump(@items)); 
}

1;
__END__

=head1 NAME

Angerwhale::View::Feed::YAML - Syndicated YAML

=head1 IMPORTANT NOTE

L<YAML|YAML> Ain't Markup Language.

=head1 DESCRIPTION

Outputs articles as YAML

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
