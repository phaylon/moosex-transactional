package # hooks test
    MooseX::Transactional::Test::Hooks;
use Moose;
use MooseX::Transactional;

has foo => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

my $CallIndex = 1;
my %CallOrder;
my %CallValue;
sub call_order { my $self = shift; $CallOrder{ $self } }
sub call_value { my $self = shift; $CallValue{ $self } }

sub TRANSACTION {
    my ($self, $data) = @_;
    push @{ $CallOrder{ $self }{TRANSACTION} }, ["$self", $CallIndex++];
    push @{ $CallValue{ $self }{TRANSACTION} }, [@_];
}

sub COMMIT {
    my ($self, $data) = @_;
    push @{ $CallOrder{ $self }{COMMIT} }, ["$self", $CallIndex++];
    push @{ $CallValue{ $self }{COMMIT} }, [@_];
}

sub ROLLBACK {
    my ($self, $data) = @_;
    push @{ $CallOrder{ $self }{ROLLBACK} }, ["$self", $CallIndex++];
    push @{ $CallValue{ $self }{ROLLBACK} }, [@_];
}

1;
