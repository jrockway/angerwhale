package Angerwhale;

use strict;
use warnings;
use File::Temp qw(tempdir);
use Catalyst qw/Unicode ConfigLoader Scheduler Static::Simple
		Cache::FastMmap LogWarnings Setenv 
		ConfigLoader::Environment C3/;

our $VERSION = '0.01_01';

binmode STDOUT, ':utf8';

__PACKAGE__->config({name => __PACKAGE__});
__PACKAGE__->config->{static}->{mime_types} = 
  {
   svg => 'image/svg+xml',
   js  => 'text/javascript',
  };
__PACKAGE__->config->{cache}->{storage} = tempdir(CLEANUP => 1);
__PACKAGE__->config->{cache}->{expires} = 43200; # 12 hours

__PACKAGE__->config({VERSION => $VERSION});

__PACKAGE__->setup;
__PACKAGE__->schedule( at    => '25 * * * *',
		       event => '/scheduledevents/clean_sessions', );

1;

__END__

=head1 NAME

Angerwhale - Blog software without the unsightly database.

=head1 SYNOPSIS

See L<Catalyst|Catalyst>.

=head1 BUGS

Tons, possibly :)

Report to L<http://www.jrock.us/trac/blog_software/new_ticket>

=head1 AUTHOR

Jonathan Rockway C<< <jrockway AT cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2006 Jonathan Rockway

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

