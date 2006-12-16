#!/usr/bin/perl
# articles_and_comments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests posting of articles and comments against the real server

my $tmp;
BEGIN {
    use Directory::Scratch;
    $tmp  = Directory::Scratch->new;
    my $base = $tmp->base;
    $ENV{'ANGERWHALE_description'} = 'You should not be seeing this';
    $ENV{'ANGERWHALE_base'} = $base;
    $ENV{'ANGERWHALE_title'} = 'Unit Tests Are Fun';
}

##
use Test::More tests=>19;
##

use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
use File::Attributes qw(get_attribute list_attributes);
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/');
$mech->has_tag('title', 'Unit Tests Are Fun', 'correct title');
$mech->content_contains('No articles to display.', 'no articles yet');

my $title = 'This is a test';

$tmp->touch($title, 'This is a test article.');
my $article = $tmp->exists($title);
ok($article, 'created article OK');
is(scalar list_attributes($article), 0, 'no attributes');

$mech->get_ok('/');

is(get_attribute($article, 'title'), undef, 'title was not set');
my $guid = get_attribute($article, 'guid');
ok($guid, 'guid was set');

$mech->content_contains($title, 'page contains title');
$mech->content_contains('Read more...', 'page contains read more link');
$mech->content_contains('no comments', 'page contains no comments');
$mech->content_contains('This is a test article.', 'page contains article');

# -- try the article page now
SKIP: {
    skip 'WWW::Mech is toasted', 7; 
    $mech->get_ok("/articles/$title");
    $mech->content_contains($title, 'article page contains its title');
    $mech->content_contains('This is a test article.', 'page contains article');
    $mech->content_contains('no comments', 'page contains no comments');
    $mech->content_contains('Post a comment', 'page contains post comment link');
    
    # post a comment
    $mech->follow_link_ok({text => 'Post a comment'}, 'trying to post a comment');
    
    ok($mech->submit_form(
			  fields => { title => 'test comment',
				      body  => 'This is a test comment!',
				      type  => 'text',
				    },
			  button => 'Post'
			 ), 'submit a comment OK');
}

END {
    #diag(q"Unlinking angerwhale_test.yml");
    unlink q"angerwhale_test.yml";
}
