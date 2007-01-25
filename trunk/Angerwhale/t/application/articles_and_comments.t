#!/usr/bin/perl
# articles_and_comments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests posting of articles and comments against the real server
use strict;

my $tmp;
my $blog_title;
my $blog_desc;
BEGIN {
    use Directory::Scratch;
    $tmp  = Directory::Scratch->new;
    my $base = $tmp->base;
    
    $blog_title = "Unit Tests Are Fun - $$";
    $blog_desc  = 'You should not be seeing this.';
    
    $ENV{'ANGERWHALE_description'}  = $blog_desc;
    $ENV{'ANGERWHALE_base'}   = $base;
    $ENV{'ANGERWHALE_title'}  = $blog_title;
    $ENV{'ANGERWHALE_html'}   = 1;
}

##
use Test::More tests=>181;
##

use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
use File::Attributes qw(get_attribute list_attributes);
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/');
$mech->has_tag('title', $blog_title, 'correct title');
$mech->content_contains($blog_desc, 'description');
$mech->content_contains('No articles to display.', 'no articles yet');

for my $round (1..3){ # 23 tests
    my $a_title  = "This is a test article $$ $round";
    my $a_body = 'This is a test article.';
    $tmp->touch($a_title, $a_body);
    my $article = $tmp->exists($a_title);
    ok($article, 'created article OK');
    is(scalar list_attributes($article), 0, 'no attributes');

    $mech->get_ok('http://localhost/');

    is(get_attribute($article, 'title'), undef, 'title was not set');
    my $guid = get_attribute($article, 'guid');
    ok($guid, 'guid was set');

    $mech->content_contains($a_title, 'page contains title');
    $mech->content_contains('Read more...', 'page contains read more link');
    $mech->content_contains('no comments', 'page contains no comments');
    $mech->content_contains('This is a test article.', 'page contains article');

    # -- try the article page now
    $mech->get_ok("http://localhost/articles/$a_title");
    $mech->content_contains($a_title, 'article page contains its title');
    $mech->content_contains('This is a test article.', 'page contains article');
    $mech->content_contains('no comments', 'page contains no comments');
    $mech->content_contains('Post a comment', 'page contains post comment link');

    for my $cround (1..5){
	my $c_title = "test comment $$ $round $cround";
	my $c_body  = "This is a test comment: $$ $round $cround";

	$mech->follow_link_ok({text => 'Post a comment'}, 
			      'trying to post a comment');
    	
	ok($mech->submit_form(
			      fields => { 
					 title => $c_title,
					 body  => $c_body,
					 type  => 'text',
					},
			      button => 'Preview'
			     ), 
	   'submit comment for preview OK');
	
	$mech->content_contains($c_title, 'preview has comment title');
	$mech->content_contains($c_body , 'preview has body');
	ok($mech->submit_form(button => 'Post'), 'post the comment for real');
	
	$mech->content_contains($a_body, 'page contains article');
	
	if($cround == 1){
	    $mech->content_contains('1 comment', 'page contains 1 comment');
	}
	else {
	    $mech->content_contains("$cround comments", 
				    "page contains $cround comments");
	}
    
	$mech->content_contains($c_title,'posted comment has title');
	$mech->content_contains($c_body, 'comment has body');
    }
}
