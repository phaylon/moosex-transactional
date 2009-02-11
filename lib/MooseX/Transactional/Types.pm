=head1 NAME

MooseX::Transactional::Types - Extended Moose types

=cut

package MooseX::Transactional::Types;
use MooseX::Types::Structured qw( Tuple );
use MooseX::Types::Moose      qw( HashRef Object );
use MooseX::Types -declare => [qw( Registration ObjectMap HashBasedObject )];

use Scalar::Util qw( reftype );

use namespace::clean -except => 'meta';

=head1 DESCRIPTION

This library contains L<Moose> types used by L<MooseX::Transactional> 
and its components.

=head1 TYPES

=cut

=head2 HashBasedObject

An object with a C<HASH> L<reftype|Scalar::Util/reftype>.

=head2 Registration

An array reference with two items:

=over

=item A L</HashBasedObject>

=item A hash reference

=back

=head2 ObjectMap

A hash reference containing L</Registration>s.

=cut

subtype HashBasedObject, as Object, where { reftype $_ eq 'HASH' };
subtype Registration, as Tuple[HashBasedObject, HashRef];
subtype ObjectMap, as HashRef[Registration];

=head1 SEE ALSO

L<MooseX::Transactional>,
L<Moose>,
L<Moose::Util::TypeConstraints>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
