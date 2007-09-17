package Angerwhale::User;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;
with 'MooseX::Storage::Directory::Id';

has id => (
    is      => 'ro',
    isa     => 'Str',
    requied => 1,
);

sub get_id { shift->id };

has fullname => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

subtype EmailAddress => as 'Str' => where { /^[^@]+[@][^@]+$/ };

has email => (
    is       => 'ro',
    isa      => 'Maybe[EmailAddress]',
    required => 1,
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
