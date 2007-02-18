package Angerwhale::View::HTML;
use NEXT;
use strict;
use base 'Catalyst::View::TT';
use File::Spec;
use Angerwhale::Filter::Time;

__PACKAGE__->config(
    TOLERANT            => 1,
    TIMER               => 0,
    STRICT_CONTENT_TYPE => 1,
    RECURSION           => 1,
    DEBUG               => 1,
    COMPILE_DIR         => File::Spec->catfile(File::Spec->tmpdir, 
                                               'angerwhale', 'templates'),
);

sub process {
    my $self = shift;
    my $app = shift;
    
    my $context = $self->{template}->context;
    my $time = sub {
        my $c = $app;
        my ($context, @args) = @_;
        
        return sub {
            my $time = shift;
            return Angerwhale::Filter::Time->filter($time, \@args, 
                                                    $c->config->{date_format});
        };
    };
    $context->define_filter('time' => $time, 1);
    
    return $self->NEXT::process($app, @_);
}

=head1 NAME

Angerwhale::View::HTML - Format stash into XHTML page via TT template

=head1 SYNOPSIS

See L<Angerwhale>

=head1 DESCRIPTION

Catalyst TT View.

=head1 METHODS

=head2 process

Install filters, then process the template.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
