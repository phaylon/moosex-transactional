=head1 NAME

MooseX::Transactional::Util - Transactional utility functions

=cut

package MooseX::Transactional::Util;
use strict;
use warnings;

use aliased 'MooseX::Transactional::Stack';

use Sub::Exporter -setup => {
    exports => [qw( 
        transaction
        transaction_stack
    )],
};

=head1 SYNOPSIS

  use MooseX::Transactional::Util qw( transaction transaction_stack );
  
  # create a new transaction frame
  transaction {
  
      # prints 1
      printf "%d\n", transaction_stack->frame_count;
  };

=head1 DESCRIPTION

This package exports functions via L<Sub::Exporter> that allow the use
of classes extended with L<MooseX::Transactional> in a transactional
context.

=head1 EXPORTS

=head2 transaction_stack

Points to the global transaction stack.

=head2 transaction

This function can be used with a block:

  transaction {
      # code
  };

or with a subroutine reference:

  transaction(\&foo);

It creates a new L<stack frame|MooseX::Transactional::Stack::Frame> and C<eval>s
the passed block or subroutine. If an error occurred, all touched objects extended
with L<MooseX::Transactional> will be rolled back to their state before the transaction
that failed. The error is then rethrown. If no errors happened, the objects will be
committed.

=cut

my $TransactionStack;

sub transaction_stack () {
    $TransactionStack ||= Stack->new;
    return $TransactionStack;
}

sub transaction (&) {
    my $body = shift;
    transaction_stack->create_frame;

    my $error;
    my $result;
    do {
        $result = eval { $body->() };
        $error = $@;
    };

    if ($error) {
        transaction_stack->rollback;
        die $error;
    }

    transaction_stack->commit;
    return $result;
}

=head1 SEE ALSO

L<MooseX::Transactional>,
L<Sub::Exporter>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
