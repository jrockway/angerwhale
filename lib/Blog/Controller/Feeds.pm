package Blog::Controller::Feeds;

use strict;
use warnings;
use base 'Catalyst::Controller';
use YAML;
use Heap::Simple;
use XML::Feed;
use HTTP::Date;
use DateTime;

=head1 NAME

Blog::Controller::Feeds - Catalyst Controller

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 item_yaml($item)

YAMLizes $item and returns the text/x-yaml to the browser.  This acts
on any Filesystem::Item and includes all children!


=head2 default

The main index of all available feeds

=cut

sub default : Private {
    my ($self, $c) = @_;

    if($c->request->uri->path ne '/feeds/'){
	$c->response->redirect($c->uri_for('/feeds/'));
	return;
    }
    
    $c->stash->{template}   = 'feeds.tt';
    my @c = $c->stash->{categories} = [$c->model('Filesystem')->get_categories];
    my @t = $c->stash->{tags}       = [$c->model('Filesystem')->get_tags];
     
}

# feed of an individual article and its comments
sub article : Local {
    my ($self, $c, $article_name, $type) = @_;

    # if an article name isn't specified, redirect them to the all-articles
    # feed
    if(!defined $article_name){
	$c->response->redirect($c->uri_for("/feeds/articles/$type"));
	return;
    }

    my $article =
      eval { return $c->model('Filesystem')->get_article($article_name)};

    if(!$article){
	#404'd!
	$c->stash->{template} = 'error.tt';
	$c->response->status(404);
	return 0;
    }
    else {
	# YAML is the default
	$c->detach('item_yaml', [$article, 1]);
    }
}

sub comments : Local {
    my ($self, $c, $type) = @_;
    my $max_comments = $c->config->{max_feed_comments} || 30;
    my $heap = Heap::Simple->new(order => '>');
    
    my @todo = $c->model('Filesystem')->get_articles;
    # todo contains articles first, but comments are added inside the loop
    
    while(my $item = shift @todo){
	$heap->insert($item) if $item->isa('Blog::Model::Filesystem::Comment');
	my @comments = $item->comments;
	unshift @todo, @comments; # depth first
    }
    
    my @comments;
    eval {
	for(1..$max_comments){
	    push @comments, $c->forward('serialize_item', 
					[$heap->extract_top, 0]);
	}
    }; # stop pushing if there heap empties before $max_comments

    if($type eq 'xml' || $type eq 'xml'){
	my $title = $c->config->{title};   # My Blog - Comments
	$title .= ' - Comments' if($title);
	
	# fall back to Comments if there's no title
	$title ||= 'Comments';             
	
	my $feed = _start_xml($c, {title => $title});

	foreach my $comment (@comments){
	    my $entry = _item_xml($comment);
	    $feed->add_entry($entry);
	}

	$c->response->content_type('application/atom+xml');
	$c->response->body($feed->as_xml);
    }
    else {
	# yaml
	my $yaml = "";
	foreach my $comment (@comments){
	    $yaml .= Dump($comment);
	}
	$yaml = Dump(undef) if !$yaml;
	
	$c->response->content_type('text/x-yaml');
	$c->response->body($yaml);
    }
    
    return;
}

sub comment : Local {
    my ($self, $c, $type, @path) = @_;
    my $comment = $c->forward('/comments/find_by_path', [@path]);

    if(!$comment){
	$c->response->status(404);
	$c->stash->{template} = 'error.tt';
	return;
    }

    $c->detach('item_yaml', [$comment]);
}

sub finalize_articles : Private {
    my($self, $c, $title, $type) = @_;
    
    if($type eq 'xml'){
	$c->detach('articles_xml', $c->stash->{articles});
    }
    # make YAML the catch-all
    else {
	$c->detach('articles_yaml', $c->stash->{articles});
    }
}

sub categories : Local {
    my ($self, $c, $category, $type) = @_;
    $c->stash->{category} = $category;
    $c->forward('/categories/show_category');
    $c->forward('finalize_articles', ["Articles in $category", $type]);
}

sub tags : Local {
    my ($self, $c, $tags, $type) = @_;
    $c->forward('/tags/show_tagged_articles');
    $c->forward('finalize_articles', ["Articles tagged with $tags", $type]);
}

sub articles : Local {
    my ($self, $c, $type) = @_;
    $c->detach('categories', [q{}, $type]);
}

sub item_yaml : Private {
    my ($self, $c, $item) = @_;
    my $data = $c->forward('serialize_item', [$item, 1]);

    $c->response->content_type('text/x-yaml; charset=utf-8');
    $c->response->body(Dump($data)); 
}

sub serialize_item : Private {
    my ($self, $c, $item, $recursive) = @_;
    my $data;
    die "invalid item passed to serialize_item" 
      if !$item->isa('Blog::Model::Filesystem::Item');
    my $author = $item->author;
    my $key = 'yaml|'. $item->checksum. '|'. $item->comment_count;
    
    $data = $c->cache->get($key);
    return $data if($data);
    
    if(!$author->isa('Blog::User::Anonymous')){
	$data->{author} = { name  => $author->fullname,
			    email => $author->email,
			    keyid => $author->nice_id,  };
    }
    
    $data->{title}   = $item->title;
    $data->{type}    = $item->type;
    $data->{summary} = $item->summary;
    $data->{signed}  = $item->signed ? 1 : 0;
    $data->{html}    = $item->text;
    $data->{text}    = $item->plain_text;	
    $data->{raw}     = $item->raw_text(1);
    $data->{guid}    = $item->id;
    $data->{uri}     = $c->request->base. $item->uri;
    $data->{date}    = time2str($item->creation_time);
    $data->{modified}= time2str($item->modification_time);
    $data->{tags}    = [map {{$_ => $item->tag_count($_)}} $item->tags];
    $data->{categories} = [$item->categories] if $item->can('categories');
    
    $data->{comments} = [map {$c->forward('serialize_item', [$_, 1])} 
			 $item->comments]
      if $recursive;

    $c->cache->set($key, $data);

    return $data;
}

sub _start_xml {
    my $c      = shift;
    my $config = shift;
    
    my $feed = XML::Feed->new('Atom');
    $feed->title( $config->{title} || $c->config->{title} || 'Atom feed' );
    $feed->link( $c->req->base ); # link to the site.
    $feed->description($c->config->{description});
    $feed->generator('AngerWhale version '. $c->config->{VERSION});
    $feed->author($c->config->{author});
    $feed->language($c->config->{language}) if $c->config->{language};
    return $feed;
}

sub _item_xml {
    my $data = shift;
    my $feed_entry = XML::Feed::Entry->new('Atom');
    $feed_entry->title($data->{title});
    $feed_entry->link($data->{uri});
    $feed_entry->content($data->{html});
    $feed_entry->summary($data->{summary});
    
    foreach my $category ($data->{categories}) {
	$feed_entry->category($category);
    }
	
    if ($data->{author}) {
	my $author = $data->{author}->{fullname}. 
	  '('. $data->{author}->{email}. ')';
	$feed_entry->author($author);
    }

    $feed_entry->id($data->{guid});

    $feed_entry->
      issued(DateTime->from_epoch(epoch => str2time($data->{date})));
    if ($data->{modified} ne $data->{date}) {
	$feed_entry->
	  modified(DateTime->from_epoch(epoch => str2time($data->{modified})));
    }
    
    return $feed_entry;
}

sub articles_xml : Private {
    my ($self, $c, @articles) = @_;

    my $feed = _start_xml($c, {title => $c->config->{title}});
    
    foreach my $article (@articles){
	my $data = $c->forward('serialize_item', [$article, 0]);
	my $feed_entry = _item_xml($data);
	$feed->add_entry($feed_entry);
    }
    
    $c->response->content_type('application/atom+xml; charset=utf-8');
    $c->response->body($feed->as_xml);
}

sub articles_yaml : Private {
    my ($self, $c, @articles) = @_;
    
    my $response = q{};
    foreach my $article (@articles){
	my $data = $c->forward('serialize_item', [$article, 0]);
	$response .= Dump($data). "\n";
    }
    $response = Dump(undef) if(!$response); # return '--- ~' if there
					    # were no articles

    $c->response->content_type('text/x-yaml; charset=utf-8');
    $c->response->body($response);
}

=head2 feed_uri_for($uri, format = xml|yaml)

Given a location, returns the uri of that item's feed.

=cut

sub feed_uri_for : Private {
    my ($self, $c, $location, $type) = @_;

    $type = q{yaml} unless $type; # default to YAML
    
    if($location eq '/'){
	return "/feeds/articles/$type";
    }
    elsif($location =~ m{/categories/([^/]+)}){
	return "/feeds/categories/$1/$type";
    }
    elsif($location =~ m{/articles/([^/]+)}){
	return "/feeds/article/$1/$type";
    }
    elsif($location =~ m{/tags/([^/]+)}){
	return "/feeds/tags/$1/$type";
    }
    return q{}; # no feed for that
}


=head1 AUTHOR

Jonathan Rockway,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
