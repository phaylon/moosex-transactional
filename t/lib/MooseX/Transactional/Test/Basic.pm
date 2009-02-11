package # the basics
    MooseX::Transactional::Test::Basic;
use Moose;
use MooseX::Transactional;

has foo => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
);

has bar => (
    is          => 'ro',
    isa         => 'ArrayRef',
    default     => sub { [] },
    lazy        => 1,
);

sub baz {
    my ($self, $x) = @_;
    $self->foo($x);
    push @{ $self->bar }, $x;
}

__PACKAGE__->meta->make_immutable;

1;
