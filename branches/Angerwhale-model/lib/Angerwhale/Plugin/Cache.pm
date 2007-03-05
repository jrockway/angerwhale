# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Angerwhale::Plugin::Cache;
use strict;
use warnings;
use NEXT;
use base 'Class::Accessor::Fast';
use Compress::Zlib;
use Algorithm::IncludeExclude;
use HTTP::Date;

__PACKAGE__->mk_accessors(qw/cache_key cached_document/); 
# cache_ie_list  = include/exclude list
# cache_callback = revision callback function
# cache_key      = cache key for this request
# cached_document = cached document to serve (cache hit)

our $VERSION = '0.01';

=head1 NAME

Angerwhale::Plugin::Cache - Catalyst plugin that caches responses and
serves them when appropriate.

=head1 SYNOPSIS

    package Angerwhale;
    use Catalyst qw/... +Angerwhale::Plugin::Cache .../;

=head1 DESCRIPTION

On request, call back into the application to get a "revision number" of the
data.  If there's a cached version of this URL for the current revision, then
return the cached version instead executing the whole request.

If the server sends conditional request headers, check the condition
and send a 304 if that would be correct.

If the client supports gzip, send the gzipped version of the content, which
is computed regardless and cached along with non-gzipped version.

 (bandwidth savings)++

=head1 METHODS

=head2 cache_ie_list

include/exclude list accessor

=cut

my $ie;
sub cache_ie_list { # XXX?
    return $ie;
}


=head2 cache_callback

callback accessor

=cut

sub cache_callback { my $c = shift; return $c->config->{revision_callback} };

=head2 setup

Init the plugin

=cut

sub setup {
    my ($class, @args) = @_;
    $class->NEXT::setup(@args);
    
    die "If you're going to use Angerwhale::Plugin::Cache, you need to configure it"
      unless ref $class->config->{revision_callback} eq 'CODE';
    
    $ie = Algorithm::IncludeExclude->new; #XXX use accessor
    $ie->include();
    $ie->exclude('comments', 'post');
    $ie->exclude('static');
    $ie->exclude('login');
    $ie->exclude('captcha');
    $ie->exclude('users', 'current');
}

=head2 prepare

Get the cache ID during prepare step.

=cut

my $shut_up_about_cache_being_disabled = 0;
sub prepare {
    my ($class, @args) = @_;
    
    my $c = $class->NEXT::prepare(@args);
    
    # clear out old data
    $c->cache_key(0);
    $c->cached_document(0);

    # get callback/revision for this request
    my $callback = $c->cache_callback();
    my $revision = $callback->($c, $c->req->uri);
    
    my @path = split m{/}, $c->req->uri->path;
    shift @path;
    my $include = $c->cache_ie_list->evaluate(@path);
    
    # early return if we don't need to do caching
    return $c if keys %{ $c->flash || {} } > 0;
    return $c if (!$include); # no cache; excluded.
    return $c 
      if 'GET' ne $c->req->method &&
        'HEAD' ne $c->req->method;
    
    my $uri = $c->req->uri->as_string;
    my $key = $c->_key($revision, $uri);
    
    $c->cache_key($key);

    my $document = $c->cache('pages')->get($key);
    if ($document) {
        $c->cached_document($document);
    }
    else {
        $c->cached_document({}); # create a blank hashref for finalize_*
    }
    return $c;
}

=head2 dispatch

Kill the dispatch cycle if we're going to return a cached response.

=cut

sub dispatch {
    my ($c, @args) = @_;
    my $doc = $c->cached_document();
    
    if (ref $doc && exists $doc->{headers} && exists $doc->{body} ) {
        $c->log->debug("skipping the request cycle! fast!");
        return;
    }
    return $c->NEXT::dispatch(@args);
}

=head2 finalize

Store the document we generated during finalize_* to the cache

=cut

sub finalize {
    my ($c, @args) = @_;    

    my $key = $c->cache_key();
    my $doc = $c->cached_document();

    if ($key && !scalar @{$c->error||[]} && $c->res->status == 200) {
        ## HEADERS
        
        if (exists $doc->{headers}) {
            # we're replaying from cache
            $c->res->{headers} = $c->cached_document->{headers};
        }
        else {
            # we're storing to cache
            $doc->{mtime}    = time();
            $doc->{headers} = $c->response->headers();
        }
        
        if (!$c->_is_304($key, $doc)) {

            ## BODY
            if (exists $doc->{body}) {
                # replaying from cache
                $c->response->body($doc->{body});
            }
            else {
                # cache and gzip generated body
                $doc->{body} = q{}. $c->response->body(); # force stringify

                # gzip works on octets, not characters
                utf8::encode($doc->{body}) if utf8::is_utf8($doc->{body});
                $doc->{gzip} = Compress::Zlib::memGzip( $doc->{body} );
            }
            
            ## finish
            if ($c->_gzip_response) {
                $c->response->body($doc->{gzip});
                $c->response->content_encoding('gzip');
                $c->response->headers->push_header( 'Vary', 'Accept-Encoding' );
            }
            
            # XXX: we can do better than this
            if ($c->req->method ne 'HEAD'){
                $c->cache('pages')->set($key, $doc); 
            }
        }
        else {
            $c->response->status(304);
        }
        
        # set headers
        $c->response->headers->header( 'ETag' => qq{"$key"} );
        $c->response->headers->header( 'Last-Modified' => time2str($doc->{mtime}) );
    }
    
    $c->NEXT::finalize(@args);
}

=head2 _gzip_response

Returns true if the client would accept a gzip'd response.

=cut

sub _gzip_response {
    my $c = shift;
    my $h = $c->req->header('accept-encoding');
    return 1 if (defined $h && $h =~ /gzip/i);
    return;
}

=head2 _is_304($key, $document)

Returns true if we should 304

=cut

sub _is_304 {
    my ($c, $key, $document) = @_;
    # check for conditional requests
    my $cond_date = $c->req->header('If-Modified-Since');
    my $cond_etag = $c->req->header('If-None-Match');
    my $do_send_304 = 0;
    if ( $cond_date || $cond_etag ) {
        # if both headers are present, both must match
        $do_send_304 = 1;
        $do_send_304 = ( (str2time($cond_date)||0) >= $document->{mtime} )
          if ($cond_date);
        $do_send_304 &&= ( $cond_etag eq qq{"$key"} )
          if ($cond_etag);
    }
    return $do_send_304;
}

=head2 _key($revision, $uri)

Get the cache key for a given revision/URI pair

=cut

sub _key {
    my ($c, $revision, $uri) = @_;
    $revision ||= 0;
    $uri      ||= "NOURL";
    return "$revision:$uri";
}

=head1 CONFIGURATION

Needs a coderef in $c->config->{revision_callback} to return the revision number.

=cut

1;

