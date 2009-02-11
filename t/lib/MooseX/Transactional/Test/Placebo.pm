package # placebo object
    MooseX::Transactional::Test::Placebo;
use Moose;

has values => (
    is          => 'rw',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);

sub step {
    my ($self, $var) = @_;
    push @{ $self->values }, $var;
}

sub TRANSACTION { die "this transaction hook call shouldn't have happened" }
sub COMMIT      { die "this commit hook call shouldn't have happened" }
sub ROLLBACK    { die "this rollback hook call shouldn't have happened" }

1;
