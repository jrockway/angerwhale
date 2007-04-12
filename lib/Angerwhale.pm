package Angerwhale;

use strict;
use warnings;
use File::Spec;
use File::Remove;
use YAML::Syck qw(LoadFile);
use Catalyst qw/Unicode ConfigLoader Static::Simple
                Cache Cache::Store::FastMmap Setenv
                Session::Store::FastMmap Session::State::Cookie Session
                ConfigLoader::Environment +Angerwhale::Plugin::Cache/;

#XXX: add C3 and LogWarnings back

our $VERSION = '0.04';

my $tmp = File::Spec->catdir(File::Spec->tmpdir, 'angerwhale');
File::Remove::remove(\1, $tmp);
binmode STDOUT, ':utf8';

# load defaults
__PACKAGE__->config(LoadFile(__PACKAGE__->path_to('root', 'resources.yml')));

__PACKAGE__->config('revision_callback' => 
                    sub { 
                        my $c   = shift;
                        my $uri = shift;
                        
                        return 1 if $uri->path =~ m{/jemplate/}; # never expires
                        return $c->model('Articles')->revision;
                    }
                   );

__PACKAGE__->config( { VERSION => $VERSION } );
__PACKAGE__->setup;

# setup theme; CSS only for now
my $theme = __PACKAGE__->config->{theme} || 'phokus';
my $css =   __PACKAGE__->config->{themes}{$theme}{css};
die "Your theme is screwed up" if !ref $css;
__PACKAGE__->config->{page_includes}{css} = $css;

# kill debugging message
__PACKAGE__->log->disable('debug') if !__PACKAGE__->debug;

1;

__END__

=head1 NAME

Angerwhale - filesystem-based blog with integrated cryptography

=head1 SYNOPSIS

Angerwhale is bloging software that reads posts from the filesystem,
and determines authorship based on the post's PGP digital signature.
These posts can be in a variety of formats (text, wiki, HTML, POD),
and new formats can be added dynamically at runtime.  Posting comments
is also supported, and again, authorship is determined by checking
the digital signature.

Features include guaranteed valid XHTML 1.1 output, social tagging,
categories, syntax highlighting (see
L<http://blog.jrock.us/articles/Syntax%20Highlighting.pod> for
details), RSS and YAML feeds for every article, comment, tag, and
category, nested comments, intelligent caching of I<everything>,
space-conserving mini-posts, search-engine (and human!) friendly
archiving, a flashy default theme, and B<lots of other cool stuff>.

=head1 GETTING STARTED

Trying Angerwhale is pretty simple.  Download the tarball from
CPAN, and extract it.  Then, run 

   $ perl Makefile.PL
   $ make
   $ make test

C<make test> will run the test suite to make sure Angerwhale works on your
system.  You can then run the test server:

   $ perl script/angerwhale_server.pl

You'll then be able to connect to L<http://localhost:3000> and see
your blog.  There's already a sample post, so that should show up
and you should be able to leave a comment or log in.

If all goes well, open up the config file, C<angerwhale.yml>, and
customize the options to your heart's content.  You specifically might
want to set C<base> to some place more convenient than the
C<root/posts> directory that ships with Angerwhale.

(There are more config options than those listed; for now grep the
source for "config" to find them all.  You shouldn't need to change
the defaults, though; they're reasonable.)

=head2 Playing with Angerwhale a bit

Add a file to the C<base> you set up earlier, and you'll see it
rendered as a blog post.  Edit it, and watch Angerwhale update the
modification time (but preserve the creation time).  Sign it, and
watch your name show up on the post.  Log in (on the login page), and
add tags.  Create a subdirectory in C<base>, symlink some posts into
it, and watch them show up in a new category.  Try posting some
comments.

There's tons more you can do, so explore the code or join the IRC
channel!  Enjoy!

=head1 DEPLOYMENT

Angerwhale is a L<Catalyst|Catalyst> application, so if you'd like to
run it in a production environment, check out the
L<Catalyst deployment manual|http://search.cpan.org/~jrockway/Catalyst-Manual-5.700501/lib/Catalyst/Manual/Cookbook.pod#Deployment>.
Basically, you can run it as a FastCGI, mod_perl, or plain CGI.

=head1 RESOURCES

=over 4

=item *

IRC channel at L<irc://irc.perl.org/#angerwhale> or perhaps
L<irc://irc.perl.org/#catalyst>.

=item *

Git (revision control) at L<http://git.angerwhale.org>.

=item *

The Offical Angerwhale Blog (tm) is at
L<http://blog.jrock.us/categories/Angerwhale>.  It's updated pretty
frequently, and always has some interesting Angerwhale tips.  (And of
course, it's running Angerwhale.)

=back

=head1 TODO

Lots of things TODO.  Patches welcome; but it's best to ask on IRC
before you get started.  I'll give you a commit bit so you can work at
your leisure.

=over 4

=item * 

Image support.  Support loading OO.org or RTF documents with embedded images,
and then resize them to look nice at web resolution.

=item *

ACLs.  Based on the logged-in user's key, restrict posting or allow
them to post.  Allow administrators to delete SPAM posts, etc.

=item *

More tests.  Test coverage is pretty good (85% or so), but 100% is the goal.

=item *

More docs.  Angerwhale has a lot of nice features, but you'll only
know about them if you're me, or you hang out on IRC when I'm
implementing them.  If you're reading the code and see something you
like, send a short snippet of POD to add to the docs!  I'll love you
forever if you do!

=back

=head1 BUGS

Although Angerwhale's not yet feature complete, the code that exists
is pretty solid (it's been in use for almost a year).  

If you'd like to request a feature or report a bug, either open an RT
ticket, or join C<#angerwhale> on C<irc.perl.org>.  Thanks in advance
for your contribution.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway AT cpan.org> >>

L<http://blog.jrock.us/>

=head1 CONTRIBUTORS

These people have been nice enough to test Angerwhale and provide
patches when something didn't work quite right:

=over 4

=item * 

Ash Berlin - L<http://perlitist.com/>

=item *

Bogdan Lucaciu - L<http://blog.wiz.ro/>

=item *

Florian Ragwitz - L<http://perldition.org/>

=back

Thanks!

=head1 COPYRIGHT

Copyright (C) 2007 Jonathan Rockway and Contributors

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

=cut
