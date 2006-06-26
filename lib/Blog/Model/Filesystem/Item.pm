#!/usr/bin/perl
# Item.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::Model::Filesystem::Item;
use strict;
use warnings;

use Blog::DateFormat;
use Blog::Format;
use Blog::User::Anonymous;
use Carp;
use Data::GUID;

require File::CreationTime; # (dont want imports; conflict with my namespace)

use File::ExtAttr qw(listfattr);
use File::Find;
use File::Slurp;

use Text::WikiFormat;

use overload (q{<=>} => "compare",
	      q{cmp} => "compare",
	      fallback => "TRUE");

# for debugging

sub getfattr {
#    warn "*** getfattr: @_\n\n";
    return File::ExtAttr::getfattr(@_);
}
sub setfattr {
#    croak "*** setfattr: @_";
    return File::ExtAttr::setfattr(@_);
}


# arguments are passed in a hash ref
# base: top directory containing this item (and its friends)
# path: full path to this item

sub new {
    my ($class, $args) = @_;

    my $base      = $args->{base};
    my $path      = $args->{path};
    my $base_obj  = $args->{base_obj};
    my $parent    = $args->{parent};

    die "$base is not a valid base directory" 
      if(!defined $base || !-d $base || !-r $base);
    die "$path is not a valid path"     
      if(!defined $path || -d $path);
    die "base object was not specified" 
      if(!defined $base_obj);
    
    my $self = {};
    $self->{base}      = $base;
    $self->{path}      = $path;
    $self->{base_obj}  = $base_obj;
    $self->{parent}    = $parent;   # undefined if this is an article (as opposed to a comment)

    bless $self, $class;
    
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
	#next if $tag =~ /^\s*$/; 
	setfattr($self->{path}, "user.tags.$tag", "1");
    }
    
    return $self->tags;
}

sub tags {
    my $self = shift;
    my $filename = $self->{path};
    
    my @attributes;
    eval {
	@attributes = listfattr($filename);
    };
    
    my %taglist; # hash to avoid duplicates (due to case)
    foreach my $attribute (@attributes){
	$attribute = lc $attribute;
	if($attribute =~ /^user[.]tags[.](.+)$/){
	    $taglist{$1} = 1;
	}
    }

    
    my @taglist = keys %taglist;
    
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
    my $type = getfattr($self->{path}, 'user.type');
    
    if(!$type){
	$self->{path} =~ m{[.](\w+)$};
    };
    
    return $type;
}

sub name {
    my $self = shift;
    my $name;

    # use the title attribute if it exists
    eval {
	$name = getfattr($self->{path}, "user.title");
    };
    
    # otherwise the filename is more than adequate
    if(!$name){
	$self->{path} =~ m{([^/]+)$};
	$name = $1;
    }
    
    return $name;
}

sub title {
    my $self = shift;
    return $self->name;
}

sub id {
    my $self = shift;
    my $path = (-l $self->{path}) ? readlink($self->{path}) : $self->{path};
    my $guid;
    
    eval {
	$guid = getfattr($path, "user.guid");
	$guid = Data::GUID->from_string($guid);
    };
    return $guid->as_string if(!$@ && $guid->as_string);
      
    $guid = Data::GUID->new;
    setfattr($path, 'user.guid', $guid->as_string);

    return $guid->as_string;
}

sub creation_time {
    my $self = shift;
    
    my $ct;
    $ct = File::CreationTime::creation_time($self->{path});
    return Blog::DateFormat->from_epoch(epoch => $ct,
					time_zone => "America/Chicago");      
}

sub modification_time {
    my $self = shift;
    my $time = (stat($self->{path}))[9];
    return Blog::DateFormat->from_epoch(epoch => $time,
					time_zone => "America/Chicago");
}

sub summary {
    my $self = shift;
    my $summary = $self->text;
    
    my $SPACE = q{ };
    $summary =~ s/\s+/$SPACE/g;
    
    my @words = split /\s+/, $summary;
    if(@words > 10){
	@words = @words[0..9];
	$summary = join $SPACE, @words;
	$summary .= "…"; # utf-8 elipsis
    }
    return $summary;
}

# returns the real_key_id of the PGP signature
# you might want to validate the signature first; this routine doesn't do that
# see signed() below.
sub signor {
    my $self = shift;
    my $sig = Blog::Signature->new($self->raw_text);
    return $sig->get_key_id;
}

sub _cached_signature {
    my $self = shift;
    return getfattr($self->{path}, "user.signed");
}

sub _cache_signature {
    my $self = shift;
    # set the "signed" attribute	
    setfattr($self->{path}, "user.signed", "yes");
}

# returns signed text if signed with good signature, false otherwise
sub signed {
    my $self = shift;

    eval {
	my $sig = Blog::Signature->new($self->raw_text);
	
	# XXX: Crypt::OpenPGP is really really slow, so cache the result
	my $signed = $self->_cached_signature;

	if(defined $signed && $signed eq "yes"){
	    return $sig->get_signed_data;
	}

	else {
	    if($sig->verify){
		# and fix the author info if needed
		$self->_cache_signature;
		$self->_fix_author($sig->get_key_id);
		
		return $sig->get_signed_data;
	    }
	    
	    else {
		return;
	    }
	}
    };    
}

# if a user posts a comment with someone else's key, ignore the login
# and base the author on the signature

sub _fix_author {
    my $self   = shift;
    my $id     = shift;
    my $nice_key_id = unpack("H*", $id);
    
    setfattr($self->{path}, 'user.author', $nice_key_id);
}

sub author {
    my $self = shift;
    $self->signed; # fix the author information

    my $id = getfattr($self->{path}, "user.author");
    my $c = $self->{base_obj}->{context};
    
    if(defined $id){
	my $user = $c->model('UserStore')->get_user_by_nice_id($id);
	return $user if $user;
    }

    return Blog::User::Anonymous->new();
}

sub raw_text {
    my $self = shift;
    return scalar read_file( $self->{path} );
}

sub text {
    my $self = shift;

    my $text = $self->signed;

    if(!$text){
	$text = $self->raw_text;
    }

    return Blog::Format::format($text, $self->type);
}

# hierarchy

sub path_to_top {
    my $self = shift;
    my $parent = $self->{parent};
    
    my @path;
    if($parent){
	@path = $parent->path_to_top();
    }
    
    push @path, $self->id;
    return @path;
}

sub comment_dir {
    my $self = shift;
    my $base = $self->{base}. "/.comments/";
    
    return $base. join '/', $self->path_to_top;
}

sub comment_count {
    my $self = shift;
    my $comment_dir = $self->comment_dir;
    return 0 if !-e $comment_dir; # return 0 quickly

    my $count = 0;
    find( sub { $count ++ if !-d $File::Find::name }, $comment_dir);
    
    return $count;
}

sub comments {
    my $self = shift;
    my $comment_dir = $self->comment_dir;

    if(!-e $self->{base}. "/.comments"){
	mkdir $self->{base}. "/.comments" 
	  or die "unable to create root commentdir: $!";
    }
    if(!-e $comment_dir){
	mkdir $comment_dir or
	  die "unable to create commentdir $comment_dir: $!";
    }

    opendir my $dir, $comment_dir 
      or die "unable to open commentdir $comment_dir: $!";

    my @comments;
    while(my $file = readdir($dir)){
	my $filename = "$comment_dir/$file";
	next if -d $filename;
	next if $file =~ /^[.]/;

	my $comment = Blog::Model::Filesystem::Comment->
	  new({
	       base     => $self->{base},
	       base_obj => $self->{base_obj},
	       path     => $filename,
	       parent   => $self,
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
    
    my $comment_dir = $self->comment_dir;
    die "no comment dir $comment_dir" 
      if !-d $comment_dir;

    my $safe_title = $title;
    $safe_title =~ s{[^A-Za-z_]}{}g; # kill anything unusual

    my $filename = "$comment_dir/$safe_title";
    while(-e $filename){ # make names unique
	$filename .= " [". int(rand(10000)). "]";
    }
    
    open my $comment, '>', $filename
      or die "unable to open $filename: $!";
    eval {
	print {$comment} $body or die "io error: $!";
	print {$comment} "\n" or die "io error: $!";
	close $comment;
    };
    if($@){
	unlink $filename;
	close $comment;
	die $@; # propagate the message up
    }

    # finally, attribute the comment to someone, if possible
    if($user) {
	setfattr($filename, "user.author", $user);
    }

    # and if the safe title and real title don't match, set 
    # the title attribute
    
    $filename =~ m{/([^/]+)$}; # take into account the [##] that we added
    $safe_title = $1;

    if($title ne $safe_title){
	setfattr($filename, "user.title", $title);
    }

    # finally, set the type
    if(defined $type){
	setfattr($filename, "user.type", $type);
    }
    
    return;
}

sub post_uri {
    my $self = shift;
    my $uri  = $self->uri;
    $uri =~ s{/comments/}{/comments/post/};
    return $uri;
}

1;
