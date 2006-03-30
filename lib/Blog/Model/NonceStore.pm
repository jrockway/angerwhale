package Blog::Model::NonceStore;

use strict;
use warnings;
use base 'Catalyst::Model';
use NEXT;
use YAML qw(LoadFile DumpFile);
use Crypt::Random qw(makerandom);
use Blog::Challenge;

sub new {
    my ($self, $c) = @_;
    $self = $self->NEXT::new(@_);
    
    my $dir = $self->{sessions};
    mkdir $dir;
    mkdir "$dir/pending";
    mkdir "$dir/established";
    
    die "$dir isn't a valid session directory" if(!-d $dir || !-w $dir);
    return $self;
}

# takes a Blog::Challenge object
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
    my $self = shift;
    my $challenge = shift;
    die if !$challenge->{nonce};

    my $nonce = $challenge->{nonce};
    # prevent people from specifying the nonce as "../../../../etc/passwd"
    # and fucking the system over
    $nonce =~ s/[^0-9]//g;
    
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
    my $uid  = $user->id;

    my $sid  = makerandom(Size => 256);
    my $dir  = $self->{sessions} . "/established";
    
    DumpFile("$dir/$sid", {uid => $uid});
    warn "we made it here $sid";
    return $sid;
}

# given session id, returns keyid of user
sub unstore_session {
    my $self = shift;
    my $sid = shift;
    my $dir = $self->{sessions};
    
    my $file = LoadFile("$dir/$sid");
    return $file->{uid};
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
