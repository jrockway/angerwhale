package Blog;

use strict;
use warnings;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the application's root 
# directory
#

use Catalyst qw/-Debug Unicode ConfigLoader Static::Simple Prototype Scheduler/;

__PACKAGE__->config({name => __PACKAGE__});

#our $VERSION = '0.01';

#
# Start the application
#

__PACKAGE__->setup;

#__PACKAGE__->schedule( at    => '25 * * * *',
#		       event => '/scheduledevents/clean_sessions', );

#
# IMPORTANT: Please look into Blog::Controller::Root for more
#

=head1 NAME

Blog - Catalyst based application

=head1 SYNOPSIS

    script/blog_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 SEE ALSO

L<Blog::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
