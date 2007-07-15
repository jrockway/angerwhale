/* display an angerwhale json feed as HTML */

function get_feed(count, where) {
    var d = loadJSONDoc('feed.json');

    var error = function (error) { 
        $('posts').innerHTML = 'Error loading posts: ' + error;
    }
    
    var display_posts = function (posts){
        var formatted = [];
        for(var i = 0; i < count; i++){
            // i hate javascript.
            try {
                var post;   
                post = posts[i];
                log('loaded', post.title);
                formatted[i] = format_post(post);
                
            }
            catch (e){
                log("no more posts");
                break;
            }
        }
        
        log('rendering');
        swapDOM($(where), UL({ id: 'posts_ul' }, formatted));
    };
    d.addCallbacks(display_posts, error);
}

function format_post(post)
{
    var title   = post.title;
    var url     = post.uri;
    var summary = post.summary;
    
    return LI({ class: 'blog_post' }, A({ href: url }, title), ' - ', summary);
}

    