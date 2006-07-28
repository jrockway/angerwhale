package Blog::Controller::Feeds;

use strict;
use warnings;
use base 'Catalyst::Controller';
use YAML;

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
    $c->stash->{categories} = [$c->model('Filesystem')->get_categories];
    $c->stash->{tags}       = [$c->model('Filesystem')->get_tags];
    
}

# feed of all (recent) articles
sub articles : Local {
    my ($self, $c, $type);
    
}

# feed of an individual article and its comments
sub article : Local {
    my ($self, $c, $type, $article_name) = @_;

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
	$c->detach('item_yaml', [$article]);
    }
}

sub global_yaml : Path('/yaml') {
    my ($self, $c) = @_;
    $c->stash->{category} = q{};
    $c->forward('/categories/show_category');
    $c->detach('articles_yaml', $c->stash->{articles});
}

sub global_rss : Path('/rss'){
    my ($self, $c) = @_;
    die 'No RSS feed yet, dumbass';
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
    my $author = $item->author;
    my $key = 'yaml|'. $item->checksum. '|'. $item->comment_count;
    
    $data = $c->cache->get($key);
    return $data if($data);
    
    if(!$author->isa('Blog::User::Anonymous')){
	$data->{author} = $author->fullname. '('. $author->email. ')';
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

    $data->{comments} = [map {$c->forward('serialize_item', [$_, 1])} $item->comments]
      if $recursive;

    $c->cache->set($key, $data);

    return $data;
}

sub articles_yaml : Private {
    my ($self, $c, @articles) = @_;
    
    my $response = q{};
    foreach my $article (@articles){
	my $data = $c->forward('serialize_item', [$article, 0]);
	$response .= Dump($data). "\n";
    }
    $response = Dump(undef) if(!$response); # return "--- ~" if there were no articles
    $c->response->content_type('text/x-yaml; charset=utf-8');
    $c->response->body($response);
    warn $c->response->body;
}



=head1 AUTHOR

Jonathan Rockway,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
