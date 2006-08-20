package Blog::Model::NonceStore;

use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use YAML qw(LoadFile DumpFile);
use Crypt::Random qw(makerandom);
use Blog::Challenge;
use Blog::User::Anonymous;

sub new {
    my ($self, $c) = @_;
    $self = $self->NEXT::new(@_);
    $self->{sessions} = $c->config->{base}. '/.sessions';

    $self->{nonce_expire} = $c->config->{nonce_expire};
    $self->{session_expire} = $c->config->{session_expire};

    my $dir = $self->{sessions};
    mkdir $dir;
    mkdir "$dir/pending";
    mkdir "$dir/established";
    
    die "$dir isn't a valid session directory" if(!-d $dir || !-w $dir);
    return $self;
}

# takes a Blog::Challenge object, adds the nonce to that object,
# and returns the filename of the nonce object on success
sub new_nonce {
    my $self = shift;
    my $challenge = shift;
    die if !$challenge->{nonce};
    
    my $dir  = $self->{sessions}. "/pending";
    my $file = $dir. "/". $challenge->{nonce};
    
    open my $store, '>', $file 
      or die "could not create a new session file in $dir: $!";
    
    print {$store} $challenge. "\n";
    close $store;
    
    return $file;
}

# verification can ONLY HAPPEN ONCE!
sub verify_nonce {
    my $self      = shift;
    my $challenge = shift;
    die if !$challenge->{nonce};

    my $nonce = $challenge->{nonce};
    # prevent people from specifying the nonce as "../../../../etc/passwd"
    # and fucking the system over
    if($nonce =~ m/[^0-9]/){
	die "invalid nonce $nonce"
    }
    
    my $dir  = $self->{sessions}. "/pending";
    my $file = $dir. "/". $nonce;
    my $old_challenge;

    eval {
	# desearliaze the old challenge
	$old_challenge = LoadFile($file)
	  or die "could not open session file in $dir: $!";

	# file can't be removed unless it's valid YAML.
	unlink $file or warn "couldn't remove session file $file: $!";
    };
    
    if($@){
	return;
    }

    # and compare it to the one we already had
    return $challenge == $old_challenge;
}

# needs user object, returns session id
sub store_session {
    my $self = shift;
    my $user = shift;
    my $uid  = $user->nice_id;

    my $sid  = makerandom(Size => 256);
    my $dir  = $self->{sessions} . "/established";
    
    DumpFile("$dir/$sid", {uid => $uid});
    return $sid;
}

# given session id, returns keyid of user
sub unstore_session {
    my $self = shift;
    my $sid = shift;
    my $dir = $self->{sessions};
    $sid =~ s/[^0-9]//g;

    my $file;
    eval {
	$file = LoadFile("$dir/established/$sid");
    };
    
    return $file->{uid} if $file;
    die "No such session $sid ($@)";
}

sub clean_sessions {
    my $self    = shift;
    my $timeout = $self->{session_expire} || 3600;
    my $dir     = $self->{sessions}. '/established';

    return _clean($timeout, $dir);
}

sub clean_nonces {
    my $self    = shift;
    my $timeout = $self->{nonce_expire} || 3600;
    my $dir     = $self->{sessions}. '/pending';

    return _clean($timeout, $dir);
}


sub _clean {
    my $timeout = shift;
    my $dir     = shift;

    my $count = 0;
    opendir my $dh, $dir or die;
    while(my $file = readdir $dh){
	next if $file eq '.';
	next if $file eq '..';
	
	my $path  = "$dir/$file";
	my $mtime = (stat $path)[9];
	if((time() - $mtime) > $timeout){
	    $count += unlink $path;
	}
    }
    closedir $dh;
    
    return $count;
}


=head1 NAME

Blog::Model::NonceStore - stores session information in the filesystem

=head1 SYNOPSIS

See L<Blog>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jonathan Rockway

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
