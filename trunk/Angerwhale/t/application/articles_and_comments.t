#!/usr/bin/perl
# articles_and_comments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# tests posting of articles and comments against the real server

my $tmp;
BEGIN {
    use Directory::Scratch;
    use YAML qw(DumpFile);

    $tmp  = Directory::Scratch->new;
    my $base = $tmp->base;
    $ENV{'ANGERWHALE_CONFIG_LOCAL_SUFFIX'} = 'test';
    
    my $config = { base        => $base,
		   title       => 'Unit Tests Are Fun',
		   description => 'You should not be seeing this',
		   feeds       => []
		 };
    
    DumpFile('angerwhale_test.yml', $config);
}

##
use Test::More tests=>23;
##

use Test::WWW::Mechanize::Catalyst qw(Angerwhale);
use File::Attributes qw(get_attribute list_attributes);
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/');
SKIP: {
    skip 'Test::WWW::Mechanize is broken on XHTML', 1;
    $mech->title_is('Unit Tests Are Fun');
}
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
$mech->get_ok("/articles/$title");
$mech->content_contains($title, 'article page contains its title');
$mech->content_contains('This is a test article.', 'page contains article');
$mech->content_contains('no comments', 'page contains no comments');
$mech->content_contains('Post a comment', 'page contains post comment link');

# post a comment
SKIP: {
    skip q{This doesn't work yet}, 6;
    $mech->follow_link_ok({text => 'Post a comment'}, 'trying to post a comment');
    die Dump($mech);
    ok($mech->form_number(0));
    ok($mech->set_fields(title => 'test comment'));
    ok($mech->set_fields(body  => 'This is a test comment!'));
    ok($mech->select(type => 'text'));
    ok($mech->click("Post"));
}

END {
    #diag(q"Unlinking angerwhale_test.yml");
    unlink q"angerwhale_test.yml";
}
