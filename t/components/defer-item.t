#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 13;

my @real_kids = qw/There is only XUL/;

my $test = TestItem->new;
is_deeply $test->children, [], 'no kids';

$test->children([qw/A B C/]);
is_deeply $test->children, [qw/A B C/], 'A B C, non-deferred';

$test = TestItem->new;
$test->children(sub { [qw/A B C D/] });
is ref $test->{_defer_children}, 'CODE', 'coderef for deferring kids';
is_deeply $test->children, [qw/A B C D/], 'got deferred children';
is_deeply $test->children, [qw/A B C D/], 'got deferred children again';
ok !$test->{_defer_children}, 'ref went away';

$test = TestItem->new;
my $ran = 0;
$test->children(sub { $ran++; [map { uc } $_[0]->_children] });
ok !$ran, "didn't run yet";
is ref $test->{_defer_children}, 'CODE', 'deferred children with _children';
is_deeply $test->children, [qw/THERE IS ONLY XUL/];
ok $ran, "filter ran";
is_deeply $test->children, [qw/THERE IS ONLY XUL/];
is $ran, 1, "filter didn't run twice";
ok !$test->{_defer_children}, 'ref went away';

package TestItem;
use base 'Angerwhale::Content::Item';
sub _children { @real_kids };
