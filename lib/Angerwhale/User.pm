package Angerwhale::User;
use Moose;
use Moose::Util::TypeConstraints qw/subtype as where/;
use MooseX::Storage;
with 'MooseX::Storage::Directory::Id';

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub get_id {
    my $self = shift;
    return $self->type . ':'. $self->id;
}

has fullname => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

subtype EmailAddress => as 'Str' => where { /^[^@]+[@][^@]+$/ };

has email => (
    is       => 'rw',
    isa      => 'Maybe[EmailAddress]',
    required => 0,
);

has traits => (
    is         => 'ro',
    isa        => 'ArrayRef[ClassName]',
    auto_deref => 1,
);

sub BUILD {
    my $self = shift;
    
    for my $t (map { Class::MOP::load_class($_); $_ } $self->traits){
        $t->meta->apply($self);
    }
}

1;
__END__

=head1 NAME

Angerwhale::User - represents a user or author

=head1 ATTRIBUTES

=head2 new

=head2 id

=head2 fullname

=head2 email

=cut
