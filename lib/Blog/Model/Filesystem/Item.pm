#!/usr/bin/perl
# Item.pm - [description]
# Copyright (c) 2006 Jonathan T. Rockway
# $Id: $

package Blog::Model::Filesystem::Item;
use strict;
use warnings;

use File::Slurp;
use File::ExtAttr qw(getfattr setfattr);
use File::CreationTime;

use Text::WikiFormat;
use Data::GUID;

use Blog::DateFormat;
use Blog::User;

use overload (q{<=>} => "compare",
	      q{cmp} => "compare",
	      fallback => "TRUE");

# arguments are passed in a hash ref
# base: top directory containing this item (and its friends)
# path: full path to this itme

sub new {
    my ($class, $args) = @_;

    my $base      = $args->{base};
    my $path      = $args->{path};
    my $base_obj  = $args->{base_obj};
    my $parent    = $args->{parent};

    die "$base is not a valid base directory" if(!defined $base || !-d $base || !-r $base);
    die "$path is not a valid path" if(!defined $path || -d $path);
    die "base object was not specified" if(!defined $base_obj);
    
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
    map {s{(?:\s|[_;,!.])}{}g;} @tags;
    
    my %tags;
    @tags = (@tags, $self->tags);
    
    foreach my $tag (@tags){
	next if $tag =~ /^\s*$/;
	$tags{$tag} = 1;
    }

    my $mytags = join ';', sort keys %tags;
        
    setfattr($self->{path}, "user.tags", $mytags);
    return $self->tags;
}

sub tags {
    my $self = shift;
    my $filename = $self->{path};
    
    my $taglist;
    eval {
	$taglist = getfattr($filename, "user.tags");
    };
    $taglist = lc $taglist;
    
    my @taglist;
    @taglist = split ';', $taglist if defined $taglist;
    @taglist = grep {$_ !~ /(?:\s|[_;,!.])+/} @taglist;

    if(wantarray){
 	my %in;
	return sort map {$in{$_}++; $_ if $in{$_} < 2;} @taglist; # remove dupes
    }

    $taglist = join ';', @taglist; # fix empty;;elements;etc.;
    return $taglist;
}

## basic metadata

sub name {
    my $self = shift;
    my $base = $self->{base};
    $self->{path} =~ m{([^/]+)$};
    my $name = $1;
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
    my $summary;

    open my $data, '<', $self->{path}
      or die "cannot open $self->{path} for reading: $!";

    while(my $line = <$data>){
	chomp $line;
	if($line){
	    $summary = $line;
	    last;
	}
    }
    
    my $SPACE = q{ };
    $summary =~ s/\s+/$SPACE/g;
    
    my @words = split /\s+/, $summary;
    @words = @words[0..9];
    $summary = join $SPACE, @words;
    $summary .= "...";
    return $summary;
}

sub author {
    my $self = shift;
    my $id = getfattr($self->{path}, "user.author");
    
    return Blog::User->new({id => $id});
}

sub raw_text {
    my $self = shift;
    return scalar read_file( $self->{path} );
}

sub text {
    my $self = shift;
    my $text = $self->raw_text;
    
    return Text::WikiFormat::format($text,
				    {
				     newline => "",
				     paragraph	=> [ '<p>', "</p>\n", ' ',],
				    },
				    {
				     implicit_links=>0,
				     extended=>1
				    }); 
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
    my $base = $self->{base}. "/_comments/";
    
    return $base. join '/', $self->path_to_top;
}

sub comment_count {
    my $self = shift;
    my $comment_dir = $self->comment_dir;
    
    my @files = grep { chomp; !-d $_ } `find $comment_dir`;
    
    return scalar @files;
}

sub comments {
    my $self = shift;
    my $comment_dir = $self->comment_dir;

    if(!-e $self->{base}. "/_comments"){
	mkdir $self->{base}. "/_comments" 
	  or die "unable to create root commentdir: $!";
    }
    if(!-e $comment_dir){
	mkdir $comment_dir or die "unable to create commentdir $comment_dir: $!";
    }

    opendir my $dir, $comment_dir 
      or die "unable to open commentdir $comment_dir: $!";

    my @comments;
    while(my $file = readdir($dir)){
	my $filename = "$comment_dir/$file";
	next if -d $filename;
	next if $file =~ /^[.]/;

	my $comment = Blog::Model::Filesystem::Comment->
	  new({base     => $self->{base},
	       base_obj => $self->{base_obj},
	       path     => $filename,
	       parent   => $self});

	push @comments, $comment;
    }
    closedir $dir;
    
    return @comments;
}

sub add_comment {
    my $self = shift;
    my $title = shift;
    my $body = shift;

    $title =~ s{/}{}g;
    $title =~ s/^[.]+//;
    
    die "no data" if (!$title || !$body);
    
    my $comment_dir = $self->comment_dir;
    die "no comment dir $comment_dir" 
      if !-d $comment_dir;

    my $desired = "$comment_dir/$title";
    if(-e $desired){ # make names unique
	$desired .= " [". int(rand(10000)). "]";
    }

    open my $comment, '>', $desired
      or die "unable to open $desired: $!";
    eval {
	print {$comment} $body or die "io error: $!";
	print {$comment} "\n" or die "io error: $!";
	close $comment;
    };
    if($@){
	unlink "$desired";
	close $comment;
	die $@; # propagate the message up
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
