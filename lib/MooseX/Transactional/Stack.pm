=head1 NAME

MooseX::Transactional::Stack - Manage nested transactions

=cut

package MooseX::Transactional::Stack;
use Moose;
use MooseX::Types::Moose    qw( ArrayRef );
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Carp    qw( croak );

use aliased 'MooseX::Transactional::Stack::Frame';

use namespace::clean -except => 'meta';

=head1 SYNOPSIS

  use MooseX::Transactional::Util qw( transaction_stack );
  my $stack = transaction_stack;
  
  # stackframes attribute
  $stack->add_frame($frame_obj);
  my $nearest_frame = $stack->remove_frame;
  say 'count: ', $stack->frame_count;
  my $top_frame = $stack->get_frame(0);
  
  # nearest without removing
  my $nearest_frame = $stack->current_frame;
  
  # all but the nearest
  my @parents = $stack->parent_frames
  
  # register object for top frame
  $stack->register_object($transactional_object);
  
  # create and add new frame
  my $frame = $stack->create_frame;
  
  # commit or rollback current frame
  $stack->rollback;
  $stack->commit;

=head1 DESCRIPTION

This class represents the global stack for L<MooseX::Transactional> allowing
transactions to be nested. Each L<MooseX::Transactional::Stack::Frame> object
stored in the L</stackframes> attribute will have registrations of all touched
objects below that scope.

=head1 ATTRIBUTES

=cut

=head2 stackframes

Array reference of L<MooseX::Transactional::Stack::Frame> objects, each
representing a transaction level. This attribute is readonly.

=cut

has stackframes => (
    metaclass   => 'Collection::Array',
    is          => 'ro',
    isa         => ArrayRef[Frame],
    required    => 1,
    default     => sub { [] },
    lazy        => 1,
    provides    => {
        'push'      => 'add_frame',
        'pop'       => 'remove_frame',
        'count'     => 'frame_count',
        'get'       => 'get_frame',
    },
);

=head1 METHODS

=head2 add_frame( Object $frame )

Adds the object C<$frame> to the L</stackframes>.

=head2 remove_frame()

Will remove the current frame from the stack, if there is one.

=head2 frame_count()

Will return the number of frames in the stack.

=head2 get_frame( Int $index )

Returns the frame object in the L</stackframes> attribute at the passed
C<$index>. E.g.

  $stack->get_frame(0);

will return the topmost frame in the stack.

=cut

=head2 parent_frames()

This will return a list of all frames I<except> the current one.

=cut

method parent_frames {
    return @{ $self->stackframes }[0 .. $#{ $self->stackframes } - 1];
}

=head2 register_object( Object $object )

This registers the passed C<$object> in the L</current_frame()>.

=cut

method register_object (Object $obj) {
    
    # no transaction
    my $frame = $self->current_frame
        or return undef;

    # pass the parent frames so the frame can store his registrations
    # at a higher level
    $frame->register_object($obj, [$self->parent_frames]);

    return 1;
}

=head2 create_frame()

Creates, L<adds|/add_frame( Object $frame )> and returns a new 
L<MooseX::Transactional::Stack::Frame> object.

=cut

method create_frame {

    # create and add
    my $frame = Frame->new;
    $self->add_frame($frame);

    # always return new frame
    return $frame;
}

=head2 commit()

This will commit all objects registered in the current frame or
die if there is no current frame. The current frame will also
be removed from the stack.

=cut

method commit {

    # we need to have a frame
    my $frame = $self->remove_frame
        or croak 'Tried to commit outside of transaction';

    # commit all registrations
    return $frame->commit;
}

=head2 rollback()

Used to rollback all objects registered in the current frame. It
will remove the current frame from the stack. An error will be thrown 
if there is no frame to rollback.

=cut

method rollback {

    # we need a frame to rollback
    my $frame = $self->remove_frame
        or croak 'Tried to rollback outside of transaction';

    # rollback all registrations
    return $frame->rollback;
}

=head2 current_frame()

Returns the current transaction frame or an undefined value if
no transaction scope exists.

=cut

method current_frame () {

    # np transaction
    return undef 
        if not $self->frame_count;

    # nearest frame
    return $self->get_frame(-1);
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<MooseX::Transactional>,
L<MooseX::Transactional::Stack::Frame>,
L<Moose>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
