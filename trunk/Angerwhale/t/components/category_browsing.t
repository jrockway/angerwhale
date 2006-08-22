#!/usr/bin/perl
# category_browsing.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use strict;
use warnings;

use Test::More tests=>20;
use Test::MockObject;
use ok 'Angerwhale::Controller::Categories';

my $c = Test::MockObject->new;
my $articles = Test::MockObject->new;
my $num_articles = 200;
my @_articles = (1..$num_articles);
my @articles;
my $ctime = 0;
my $time_sep = 1_000_000;

foreach (@_articles){
    my $a = Test::MockObject->new;
    $a->set_always('title', $_);
    $a->set_always('mini', 0);
    $a->set_always('words', 500);
    $a->set_always('creation_time', $ctime+=$time_sep);
    push @articles, $a;
}
@articles = reverse @articles;

my $o = bless \my $foo, 'Angerwhale::Controller::Categories';
my ($before, $current, $after) = 
  $o->_split_articles([@articles],
		{articles_per_page => 1}
	       );
is(ref $before, 'ARRAY', "before exists");
is(ref $current, 'ARRAY', "current exists");
is(ref $after, 'ARRAY', "after exists");
ok(!$before->[0], "no before");
ok($current->[0], "first current");
ok($after->[0], "first after");
ok($after->[1], "second after");

my @date_after_10_articles = (localtime($time_sep*($num_articles-10)))[5,4,3];
$date_after_10_articles[0] += 1900;
$date_after_10_articles[1] += 1; # Jan = 0

my $per_page = 15;
($before, $current, $after) = 
  $o->_split_articles([@articles],
		      {articles_per_page => $per_page,
		       date => [@date_after_10_articles]});

is(ref $before, 'ARRAY', "before exists");
is(ref $current, 'ARRAY', "current exists");
is(ref $after, 'ARRAY', "after exists");

my @before = @{$before};
my @current = @{$current};
my @after = @{$after};

is(scalar @current, $per_page, "$per_page current articles");
is(scalar @before, 10, "10 newer ('before') articles"); 
is(scalar @after, $num_articles-(10+$per_page), 
   'right number of older articles');

# test that mini articles are skipped
$articles[$per_page+3]->set_always('mini', 1);
($before, $current, $after) = 
  $o->_split_articles([@articles],
		      {articles_per_page => $per_page,
		       date => [@date_after_10_articles]});

@before	  = @{$before};
@current  = @{$current};
@after	  = @{$after};

is(scalar @current, $per_page+1, "$per_page + 1 current articles");
is(scalar @before, 10, "10 newer ('before') articles"); 
is(scalar @after, $num_articles-(10+$per_page+1), 
   'right number of older articles');

### now test date spill-over

my $time = $articles[10]->creation_time;
$articles[$_]->set_always('creation_time', $time) for (10..39);


($before, $current, $after) = 
  $o->_split_articles([@articles],
		      {articles_per_page => $per_page,
		       date => [@date_after_10_articles]});

@before	  = @{$before};
@current  = @{$current};
@after	  = @{$after};

is(scalar @current, 30, "30 same day current articles");
is(scalar @before, 10, "10 newer ('before') articles"); 
is(scalar @after, $num_articles-40, 
   'right number of older articles (long page)');

# done





















__END__
$articles->set_always('get_articles', @articles);
$articles->set_always('get_by_category', @articles);
$c->set_always('config', {articles_per_page => 1,
			  mini_cutoff => -1});
$c->set_always('stash', {category => q{/}, root => $articles});

my $o = bless \my $foo, 'Angerwhale::Controller::Categories';
eval {
    $o->show_category($c);
};
ok(!$@, "survived call without date");
warn $@ if $@;

my @current = @{$c->stash->{articles}};
is(scalar @current, 1, "one current article");
isa_ok($current[0], "Test::MockObject");
is($current[0]->title, '1foo', "foo is current article");
ok($c->stash->{newest_is_newest}, "no newer articles");
ok(!$c->stash->{newer_ariticles}, 'no date for newer articles');


