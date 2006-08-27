#!/usr/bin/perl
# Item.pm - a Filesystem item (Article or Comment, usually)
# Copyright (c) 2006 Jonathan T. Rockway

package Angerwhale::Model::Filesystem::Item;
use strict;
use warnings;

use base qw(Class::Accessor); #mixin some accessors 
__PACKAGE__->mk_accessors(qw(base location parent context));

use Angerwhale::Format;
use Angerwhale::User::Anonymous;
use Angerwhale::Signature;
use Carp;
use Data::GUID;
use Digest::MD5 qw(md5_hex);
use Encode;
# (dont want imports; they conflict with my namespace)
require File::CreationTime; 
use File::Attributes qw(list_attributes get_attribute set_attribute);
use File::Find;
use File::Slurp;

# make sort @articles sort by creation time
use overload (q{<=>} => \&compare,
	      q{cmp} => \&compare,
# but still let other stuff work too	    
	      fallback => "TRUE");

use utf8; # for the elipsis later on

=head1 NAME

Angerwhale::Model::Filesystem::Item - a filesystem item that knows how
to attach other C<Item>s to itself

=head1 SYNOPSIS

=head1 METHODS

=head2 new( \%arguments )

Creates a new Filesystem::Item; but you probably want
C<Filesystem::Item::Article> or C<Filesystem::Item::Comment> instead.

Arguments:

=over 4

=item base 

[REQUIRED] The directory to read filesystem items from.

=item path

[REQUIRED] The file used to back this item.  Must exist, and must be a
regular file.

=back

=cut

# arguments are passed in a hash ref
# base: top directory containing this item (and its friends)
# path: full path to this item
sub new {
    my ($class, $args) = @_;
    die Carp::longmess "Unexpected path: $args->{path}" if $args->{path};
    my $base      = $args->{base};
    my $location  = $args->{location};
    my $parent    = $args->{parent};
    my $context   = $args->{context};
    
    croak "$base is not a valid base directory" 
      if(!defined $base || !-d $base || !-r $base);
    croak "$location is not a valid path"     
      if(!defined $location || -d $location);
    croak "need a valid Angerwhale context"
      if(!defined $context);
    my $self = {};
    bless $self, $class;
    
    $self->base($base);
    $self->location($location);
    $self->context($context);
    # undefined if this is an article (as opposed to a comment)
    $self->parent($parent);
    
    return $self;
}

sub compare {
    my $a = shift;
    my $b = shift;

    return $a->creation_time <=> $b->creation_time;
}

## tagging support 

sub set_tag {
    my $self = shift;
    my @tags = @_;  
    map {s{(?:\s|[_;,!.])}{}g;} @tags; # destructive map
    
    foreach my $tag (@tags) {
	my $count = $self->tag_count($tag);
	$count = 0 if($count < 0);
	set_attribute($self->location, "tags.$tag", ++$count);
    }
    
    return $self->tags;
}

sub tag_count {
    my $self = shift;
    my $tag  = shift;
    return eval { get_attribute($self->location, "tags.$tag"); };
}

sub tags {
    my $self = shift;
    my $filename = $self->location;
    
    my @attributes;
    eval {
	@attributes = list_attributes($filename);
    };
    
    my %taglist; # hash to avoid duplicates (due to case)
    foreach my $attribute (@attributes){
	$attribute = lc $attribute;
	if($attribute =~ /^tags[.](.+)$/){
	    $taglist{$1} = 1;
	}
    }
    my @taglist;
    foreach my $tag (sort keys %taglist){
	# tags must be stored as utf8
	push @taglist, Encode::decode_utf8($tag);
    }

    if(wantarray){
	return @taglist;
    }
    else {
	return join ';', @taglist;
    }
}

## basic metadata

sub type {
    my $self = shift;
    my $type = eval { get_attribute($self->location, 'type')};
    
    if(!$type){
	if($self->location =~ m{[.](\w+)$}){
	    $type = $1;
	}
    }
    
    if(!$type){
	$type = 'text';
    }
    
    return $type;
}

# returns true if the article is a "mini-article"
sub mini {
    my $self = shift;

    # allow override (mostly for the controller to pass on information
    # to the view)
    my $set  = shift;
    if(defined $set){
	$self->{_is_mini} = $set;
    }
    return $self->{_is_mini} if defined $self->{_is_mini};
    
    # if not overriden, read the attribute
    my $mini = eval {get_attribute($self->location, 'mini')};
    return $mini;
}

# returns a word count
sub words {
    my $self = shift;
    my $text = $self->plain_text;

    my @words = split /\b/, $text;
    return scalar @words;
}

sub name {
    my $self = shift;
    my $name;

    $self->location =~ m{([^/]+)$};
    $name = $1;
        
    return $name;
}

sub title {
    my $self = shift;
    my $name;
    
    # use the title attribute if it exists
    eval {
	$name = get_attribute($self->location, 'title');
    };
    
    # otherwise the filename is more than adequate
    if(!$name){
	$name = $self->name;
	$name =~ s{[.]\w+$}{};
    }
    return $name;
}

sub checksum {
    my $self = shift;
    my $text = $self->raw_text;
    return md5_hex(Encode::encode_utf8($text));
}

sub id {
    my $self = shift;
    my $path = (-l $self->location) ? readlink($self->location) 
                                    : $self->location;
    my $guid;
    eval {
	$guid = get_attribute($path, 'guid');
	$guid = Data::GUID->from_string($guid);
    };
    return $guid->as_string if(!$@ && $guid->as_string);
      
    $guid = Data::GUID->new;
    
    eval {
	set_attribute($path, 'guid', $guid->as_string);
    };
    if($@){
	die "Problem setting guid on $path: $@";
    }
    return $guid->as_string;
}

sub creation_time {
    my $self = shift;
    my $ct = File::CreationTime::creation_time($self->location);
    return $ct;
}

sub modification_time {
    my $self = shift;
    my $time = (stat($self->location))[9];
    return $time;
}

sub summary {
    my $self = shift;
    my $summary = $self->plain_text;
    return if !defined $summary;
    
    my $SPACE = q{ };

    my @words = split /\s+/, $summary;
    if(@words > 10){
	@words = @words[0..9];
	$summary = join $SPACE, @words;
	my $ELIPSIS = '…';
	$summary .= " $ELIPSIS";
    }
    
    return $summary;
}

# returns the real_key_id of the PGP signature
# you might want to validate the signature first; this routine doesn't do that
# see signed() below.
sub signor {
    my $self = shift;
    my $sig = Angerwhale::Signature->new($self->raw_text(1));
    return $sig->get_key_id;
}

sub _cached_signature {
    my $self = shift;
    return eval { get_attribute($self->location, 'signed') };
}

sub _cache_signature {
    my $self = shift;
    # set the "signed" attribute	
    set_attribute($self->location, 'signed', "yes");
}

# returns true if the signature is good, false otherwise
# 1 means the signature was checked against a current key and file
# 2 means "signed=yes" was read as an attribute (from cache)
# 0 means BAD SIGNATURE!
# undef means not signed

sub signed {
    my $self = shift;

    return if $self->raw_text eq $self->raw_text(1);

    my $result = eval {
	my $sig = Angerwhale::Signature->new($self->raw_text(1));

	# XXX: Crypt::OpenPGP is really really slow, so cache the result
	my $signed = $self->_cached_signature;

	if(defined $signed && $signed eq "yes"){
	    # good signature
	    return 2;
	}
	
	if($sig->verify){
	    # and fix the author info if needed
	    $self->_cache_signature;
	    $self->_fix_author($sig->get_key_id);
	    return 1;
	}
	else {
	    die "Bad signature";
	}
    };    
    if($@){
	#"Problem checking signature on ". $self->uri. ": $@";
	return 0;
    }
    
    return $result;
}

# if a user posts a comment with someone else's key, ignore the login
# and base the author on the signature

sub _fix_author {
    my $self   = shift;
    my $id     = shift;
    my $nice_key_id = unpack("H*", $id);
    
    set_attribute($self->location, 'author', $nice_key_id);
}

sub author {
    my $self = shift;
    $self->signed; # fix the author information
    
    my $id = eval{ get_attribute($self->location, 'author')};
    
    if(defined $id){
	my $user = $self->context->model('UserStore')->get_user_by_nice_id($id);
	return $user if $user;
    }
    
    return Angerwhale::User::Anonymous->new();
}

# returns unformatted text, strips OpenPGP armour etc. if necessary
sub raw_text {
    my $self     = shift;
    my $want_pgp = shift;
    my $text     = shift || scalar read_file( $self->location,
					      binmode => ":utf8");
    $text = Encode::decode_utf8($text);
    return $text if $want_pgp;
    
    my $sig;
    eval {
	$sig = Angerwhale::Signature->new($text);
    };
    if(!$@){
	return $sig->get_signed_data;
    }
    
    return $text;
}

# returns HTML-formatted data
sub text {
    my $self = shift;
    my $text = $self->raw_text;

    my $key = "htmltext|".$self->type."|".$self->checksum;
    my $data;
    if( $data = $self->context->cache->get($key) ){
	$data = ${$data};
    }
    else {
	$data = Angerwhale::Format::format($text, $self->type); 
	$self->context->cache->set($key, \$data);
    }
    
    return $data;
}

# returns plain text formatted data
sub plain_text {
    my $self = shift;
    my $text = $self->raw_text;
    my $key = 'plaintext|'. $self->type. '|' .$self->checksum;
    
    my $data;
    if( $data = $self->context->cache->get($key) ){
	$data = ${$data};
    }
    else {
	$data = Angerwhale::Format::format_text($text, $self->type); 
	$self->context->cache->set($key, \$data);
    }
    
    return $data;
}

# hierarchy

sub path_to_top {
    my $self = shift;
    my $parent = $self->parent;
    
    my @path;
    if($parent){
	@path = $parent->path_to_top();
    }
    
    push @path, $self->id;
    return @path;}

sub path {
    my $self = shift;
    return join '/', $self->path_to_top;
}

sub comment_dir {
    my $self = shift;
    my $base = $self->base. "/.comments/";
    
    return $base. join '/', $self->path_to_top;
}

sub comment_count {
    my $self = shift;
    my $comment_dir = $self->comment_dir;
    return 0 if !-e $comment_dir; # return 0 quickly

    my $count = 0;
    find( sub { $count ++ if $self->_comment_counter($File::Find::name) }, 
	  $comment_dir);
    
    return $count;
}

sub _comment_counter {
    my $self     = shift;
    my $filename = shift;

    return if $filename =~ m{/[.][^/]+$};
    return if -d $filename;
    return if !-r $filename;

    return 1;
}

sub _create_comment_dir {
    my $self = shift;
    my $comment_dir = $self->comment_dir;
    
    if(!-e $self->base. "/.comments"){
	mkdir $self->base. "/.comments" 
	  or die "unable to create root commentdir: $!";
    }
      
    if(!-e $comment_dir){
	mkdir $comment_dir or
	  die "unable to create commentdir $comment_dir: $!";
    }  
}

sub comments {
    my $self = shift;
    my $comment_dir = $self->comment_dir;
    
    $self->_create_comment_dir;

    opendir my $dir, $comment_dir 
      or die "unable to open commentdir $comment_dir: $!";

    my @comments;
    while(my $file = readdir($dir)){
	my $filename = "$comment_dir/$file";
	next if -d $filename;
	next if $file =~ /^[.]/;

	my $comment = Angerwhale::Model::Filesystem::Comment->
	  new({
	       base     => $self->base,
	       location => $filename,
	       parent   => $self,
	       context  => $self->context,
	      });

	push @comments, $comment;
    }
    closedir $dir;
    
    return @comments;
}

sub add_comment {
    my $self = shift;
    my $title = shift;
    my $body = shift;
    my $user = shift;
    my $type = shift;
    
    die "no data" if (!$title || !$body);
    
    $self->_create_comment_dir;
    my $comment_dir = $self->comment_dir;
    die "no comment dir $comment_dir" 
      if !-d $comment_dir;

    my $safe_title = $title;
    $safe_title =~ s{[^A-Za-z_]}{}g; # kill anything unusual

    my $filename = "$comment_dir/$safe_title";
    while(-e $filename){ # make names unique
	$filename .= " [". int(rand(10000)). "]";
    }

    ## write the comment atomically ##
    my $tmpname = $filename;
    $tmpname =~ s{/([^/]+)$}{._tmp_.$1};
    # /foo/bar/comment1337abc! -> /foo/bar/._tmp_.comment1337abc!
    # maybe make a random filename instead?

    open my $comment, '>', $tmpname
      or die "unable to open $filename: $!";
    eval {
	print {$comment} "$body\n" or die "io error: $!";
	close $comment;
	rename($tmpname => $filename) or 
	  die "Couldn't rename $tmpname to $filename: $!";
    };
    if($@){
	my $error = $@;
	eval {
	    unlink $tmpname;
	    unlink $filename; # partial rename !?
	    close $comment;
	};
	die $error; # propagate the message up
    }
    
    # set attributes: (TODO: atomic also)
    eval {
	# finally, attribute the comment to someone, if possible
	if($user) {
	    set_attribute($filename, 'author', $user);
	}
	
	# and if the safe title and real title don't match, set 
	# the title attribute
	
	$filename =~ m{/([^/]+)$}; # take into account the [##] that we added
	$safe_title = $1;
	
	if($title ne $safe_title){
	    set_attribute($filename, 'title', $title);
	}
	
	# finally, set the type
	if(defined $type){
	    set_attribute($filename, 'type', $type);
	}
    };
    if($@){
	unlink $filename;
	die "Problems seting attributes: $@";
    }
    
    return;
}

sub post_uri {
    my $self = shift;
    my $uri  = $self->uri;
    $uri =~ s{comments/}{comments/post/};
    return $uri;
}

1;
