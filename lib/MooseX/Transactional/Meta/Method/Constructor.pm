=head1 NAME

MooseX::Transactional::Meta::Method::Constructor - Immutable magic casting constructor

=cut

package MooseX::Transactional::Meta::Method::Constructor;
use Moose;

use namespace::clean -except => 'meta';

extends 'Moose::Meta::Method::Constructor';

=head1 SYNOPSIS

See L<MooseX::Transactional>.

=head1 DESCRIPTION

This will be used by L<Moose> for your L<MooseX::Transactional> using class if it
needs to construct an immutable one.

=head1 METHODS

=cut

=head2 _compile_code

Ugly, but it works. This will surround the generated code and add a call to
L<MooseX::Transactional::Role::Meta::Class/apply_transactional_magic_to_object( Object $object )>
with the newly created instance.

=cut

around _compile_code => sub {
    my ($next, $self, %args) = @_;
    
    # wrap code body with function that applies the magic
    my $body = sprintf 'sub { my $self = (%s)->(@_); $self->%s($self); return $self }',
        $args{code},
        'meta->apply_transactional_magic_to_object';

    # go on with the compilation
    return $self->$next(%args, code => $body);
};

=head1 SEE ALSO

L<MooseX::Transactional>,
L<MooseX::Transactional::Role::Meta::Class>,
L<Moose>, 
L<Moose::Meta::Method::Constructor>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
