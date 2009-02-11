=head1 NAME

MooseX::Transactional::Stack::Frame - A frame in the transactional stack

=cut

package MooseX::Transactional::Stack::Frame;
use Moose;
use MooseX::Transactional::Types qw( ObjectMap HashBasedObject );
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Carp::Clan   qr{ ^MooseX::Transactional (?: ::|$ ) }x;
use Storable     qw( dclone );
use Scalar::Util qw( refaddr );

use namespace::clean -except => 'meta';

=head1 SYNOPSIS

  my $frame = $stack->create_frame;
  
  # set registration
  $frame->set_registration_by_address($addr, [$object, $stored_data]);
  
  # get a registration
  my $registration = $frame->get_registration_by_address($addr);
  
  # get all known object addresses
  my @addresses = $frame->object_addresses;
  
  # see if the frame has a registration with a specific object address
  my $bool = $frame->has_registration_with_address($addr);
  
  # get all registrations
  my @registrations = $frame->registrations;
  
  # clear all registrations
  $frame->clear_registrations;
  
  # register a new object
  $frame->register_object($object);
  
  # rollback or commit all registered objects
  $frame->rollback;
  $frame->commit;

=head1 DESCRIPTION

This class represents a single transaction frame for L<MooseX::Transactional>. The
instances of this class are usually found in the 
L<stackframes attribute|MooseX::Transactional::Stack/stackframes> of the
L<global|MooseX::Transactional::Util/transaction_stack>
L<stack|MooseX::Transactional::Stack>.

A registration is stored by the objects L<reference address|Scalar::Util/refaddr>
and must be of the registration type defined in L<MooseX::Types/Registration>.

=head1 METHODS

=head2 set_registration_by_address( Str $address, Registration $reg )

Sets the registration associated with the reference address C<$address>
to C<$reg>.

=head2 has_registration_with_address( Str $address )

Boolean indicating if a reference with the reference address C<$address>
exists.

=head2 get_registration_by_address( Str $address )

Returns the registration associated with the reference address C<$address>.

=head2 object_addresses()

Returns the addresses of all known registrations.

=head2 registrations()

All registrations in this frame.

=head2 clear_registrations()

Clear out all registrations in this frame.

=cut

has objects => (
    metaclass   => 'Collection::Hash',
    isa         => ObjectMap,
    required    => 1,
    default     => sub { {} },
    lazy        => 1,
    provides    => {
        'set'       => 'set_registration_by_address',
        'get'       => 'get_registration_by_address',
        'keys'      => 'object_addresses',
        'exists'    => 'has_registration_with_address',
        'values'    => 'registrations',
        'clear'     => 'clear_registrations',
    },
);

=head2 register_object( Object $object, ArrayRef $parent_frames )

This will register the C<$object> in this frame and those of the
C<$parent_frames> that don't have its state in memory already.

This will call 
L<MooseX::Transactional::Role::Meta::Class/transaction_instance( Object $object, HashRef $stored_data )>
once on the C<$object>'s meta class object.

It returns the passed C<$object>'s reference address.

=cut

method register_object (Object $obj, ArrayRef $parent_frames) {

    # make sure nobody tries to register something non-hashbased. shouldn't
    # happen with moose, but nobody knows.
    croak sprintf 'Currently %s only supports objects based on hash references, but %s has a reftype of %s',
        'MooseX::Transactional',
        ref($obj),
        reftype($obj),
      unless is_HashBasedObject $obj;

    # determine objects reference address
    my $addr = refaddr $obj;

    # no need to go further if we already have this object registered
    return $addr
        if $self->has_registration_with_address($addr);

    # make a deep copy of the object's data
    my $data = dclone +{ %$obj };

    # store the data in all of our parent frames that don't know the
    # object already. this allows for skipping frames in nesting to
    # work.
    $_->has_registration_with_address($addr) 
        or $_->set_registration_by_address($addr, [$obj, $data])
      for $self, @{ $parent_frames };

    # let the meta object call the TRANSACTION hooks
    $obj->meta->transaction_instance($obj, $data);

    # reference address
    return $addr;
}

=head2 rollback()

This will rollback every registered object in this frame. It delegates
this work to each object's
L<rollback_instance|MooseX::Transactional::Role::Meta::Class/rollback_instance( Object $object, HashRef $stored_data )>
meta object method.

This will clear the registrations afterwards.

=cut

method rollback {

    # do rollback and ROLLBACK hook calls on every object
    $_->[0]->meta->rollback_instance(@$_)
        for sort { refaddr($a->[0]) cmp refaddr($b->[0]) } $self->registrations;

    # clear registrations
    $self->clear_registrations;
    return 1;
}

=head2 commit()

This will commit every registered object in this frame by calling their
L<commit_instance|MooseX::Transactional::Role::Meta::Class/commit_instance( Object $object, HashRef $stored_data )>
meta object methods. Afterwards, all registrations will be cleared.

=cut

method commit {

    $_->[0]->meta->commit_instance(@$_)
        for sort { refaddr($a->[0]) cmp refaddr($b->[0]) } $self->registrations;

    $self->clear_registrations;
    return 1;
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<MooseX::Transactional>,
L<MooseX::Transactional::Stack>,
L<MooseX::Transactional::Types>,
L<Moose>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
