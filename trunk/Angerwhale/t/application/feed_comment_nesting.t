#!perl

use strict;
use warnings;
use YAML::Syck;
use JSON;
use Angerwhale::Test (ignore_captcha => 1);
use File::Attributes qw(get_attribute);
use Test::More tests => 52;

my $mech = Angerwhale::Test->new;
$mech->article('Test Article 1');
$mech->article('Test Article 2');

my $i = 0;
my @paths;
$mech->get_ok('http://localhost/');
for my $a (1..2){ # articles
    $mech->get_ok("http://localhost/articles/Test Article $a","hit article $a");
    my $id = get_attribute($mech->tmp->exists("Test Article $a"), 'guid');
    
    my $new_id = post_comment_to($mech, $id); # reply to article
    push @paths, $new_id;
    for(1..2){ # reply to first comment
        my $new_id_2 = post_comment_to($mech, $new_id);
        push @paths, $new_id_2;
        for(1..2){ # reply to reply
            push @paths, post_comment_to($mech, $new_id_2);
        }
    }
}

=pod

Article 1          $id
  Comment 1        $id/$id1
    Comment 2      $id/$id1/$id2
      Comment 4    $id/$id1/$id2/$id4
      Comment 5    $id/$id1/$id2/$id5
    Comment 3      $id/$id1/$id3
      Comment 6    $id/$id1/$id2/$id6
      Comment 7    $id/$id1/$id2/$id7

Article 2
  ...

=cut

is($i, 14, 'correct number of comments posted');

## now test the YAML feeds

my @found_paths;
for my $a (1..2){
    $mech->get_ok("http://localhost/feeds/article/Test Article $a/yaml");
    my $yaml = $mech->content;
    my $article = Load($yaml);
    
    foreach my $comment (@{$article->{comments}||[]}){
        my $path = join '/', $article->{guid}, $comment->{guid};
        push @found_paths, $path;
        foreach my $comment2 (@{$comment->{comments}||[]}){
            my $path2 = join '/', $path, $comment2->{guid};
            push @found_paths, $path2;
            foreach my $comment3 (@{$comment2->{comments}||[]}){
                my $path3 = join '/', $path2, $comment3->{guid};
                push @found_paths, $path3;
            }
        }
    }
}

is_deeply([sort @found_paths], [sort @paths], 'found paths match (yaml)');

## and test JSON too
@found_paths = ();
for my $a (1..2){
    $mech->get_ok("http://localhost/feeds/article/Test Article $a/json");
    my $json = $mech->content;
    my $article = @{jsonToObj($json) || []}[0];
    
    foreach my $comment (@{$article->{comments}||[]}){
        my $path = join '/', $article->{guid}, $comment->{guid};
        push @found_paths, $path;
        foreach my $comment2 (@{$comment->{comments}||[]}){
            my $path2 = join '/', $path, $comment2->{guid};
            push @found_paths, $path2;
            foreach my $comment3 (@{$comment2->{comments}||[]}){
                my $path3 = join '/', $path2, $comment3->{guid};
                push @found_paths, $path3;
            }
        }
    }
}
is_deeply([sort @found_paths], [sort @paths], 'found paths match (json)');


=head2 $new_path = post_comment_to($mech, $path)

Post a comment to $path (uuid/uuid/...), and return the path of the
new comment.

Acts as 4 tests.

=cut

sub post_comment_to {
    my $mech = shift;
    my $path = shift;

    $mech->get_ok("http://localhost/comments/post/$path",
                  "get $path post page");
    
    $i++;
    ok($mech->submit_form(fields => {
                                     title => "Comment $i",
                                     body  => "Comment $i ($path)",
                                     type  => 'text',
                                    },
                          button => 'Post'
                         ));

    my $comment_dir = $mech->tmp->exists(".comments/$path");
    ok($comment_dir, 'new comment dir exists');
    
    my $comment = (
                   grep { 
                       my $a = $mech->tmp->read($_);
                       $a =~ /Comment $i \($path\)/
                   }
                   grep {
                       !-d $mech->tmp->exists($_);
                   }
                   $mech->tmp->ls(".comments/$path"))[0];
    my $id = get_attribute($mech->tmp->exists($comment), 'guid');
    my $a =0;
    $a++ while($path =~ m|/|g);
    return "$path/$id";
}
