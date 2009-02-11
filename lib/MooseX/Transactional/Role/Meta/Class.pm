=head1 NAME

MooseX::Transactional::Role::Meta::Class - Transactional role for meta classes

=cut

package MooseX::Transactional::Role::Meta::Class;
use Moose::Role;
use MooseX::Method::Signatures;

use Variable::Magic             qw( wizard cast );
use MooseX::Transactional::Util qw( transaction_stack );

use aliased 'MooseX::Transactional::Meta::Method::Constructor';

use namespace::clean -except => 'meta';

=head1 SYNOPSIS

See L<MooseX::Transactional>.

=head1 DESCRIPTION

This meta class role is applied to the class importing L<MooseX::Transactional>
by using L<Moose::Util::MetaRole> and L<Moose::Exporter>.

=head1 METHODS

=cut

=head2 constructor_class()

Returns the constructor meta class name: L<MooseX::Transactional::Meta::Method::Constructor>.

This is used for immutable classes.

=cut

method constructor_class { Constructor }

=head2 apply_transactional_magic_to_object( Object $object )

This will wiz sprinkle some L<Variable::Magic> on the passed instance that will
register the object in the current transaction (if one exists) if a slot from
the underlying hash is fetched, stored or deleted.

=cut

my $Callback = sub { transaction_stack->register_object($_[0]) };
my $Magic    = wizard map { ($_ => $Callback) } qw( fetch store delete );

method apply_transactional_magic_to_object ($meta: Object $object) {
    cast %$object, $Magic;
    return $object;
};

=head2 new_object

Extends C<new_object> found in the meta class to call 
L</apply_transactional_magic_to_object( Object $object )> on the newly created
instance.

For immutable classes, see the meta class defined via L</constructor_class()>.

=cut

around new_object => sub {
    my ($next, $meta, @args) = @_;
    my $obj = $meta->$next(@args);
    return $meta->apply_transactional_magic_to_object($obj);
};

=head2 rollback_instance( Object $object, HashRef $stored_data )

This will call every defined C>ROLLBACK> method in the class inheritance tree with
the same arguments it received. The methods will be called in order from the outmost 
(subclass) to the inmost (parent) class.

Then it will restore the C<$object> to the state defined in C<$stored_data>.

=cut

method rollback_instance ($meta: Object $obj, HashRef $data) {

    # call ROLLBACK hooks in inheritance hierarchy
    for my $rollback ($meta->find_all_methods_by_name('ROLLBACK')) {
        $rollback->{code}->execute($obj, $data);
    }

    # remove all keys that weren't there before
    for my $current_key (keys %$obj) {
        delete $obj->{ $current_key }
            unless exists $data->{ $current_key };
    }

    # restore the old keys
    my @keys = keys %$data;
    @$obj{ @keys } = @$data{ @keys };

    return 1;
}

=head2 commit_instance( Object $obj, HashRef $stored_data )

Does nothing with the C<$stored_data> by default, but provides it as a previous
state to the C<COMMIT> transaction hook methods found in the inheritance tree.
The calling order is from the outmost (subclass) to the inmost (parent) class.

=cut

method commit_instance ($meta: Object $obj, HashRef $data) {

    # call COMMIT hooks in inheritance hierarchy
    for my $commit ($meta->find_all_methods_by_name('COMMIT')) {
        $commit->{code}->execute($obj, $data);
    }

    return 1;
}

=head2 transaction_instance( Object $object, HashRef $stored_data )

Does nothing but call the C<TRANSACTION> hook method in every class and subclass
that defines it. The inmost (parent) method will be called first, then the subclasses'.

This method will be called once for every transactional clone. The calling order does
have nothing to do with the order in which the objects are defined or referenced in the
transaction block.

=cut

method transaction_instance ($meta: Object $obj, HashRef $data) {

    # call TRANSACTION hooks in inheritance hierarchy
    for my $transact (reverse $meta->find_all_methods_by_name('TRANSACTION')) {
        $transact->{code}->execute($obj, $data);
    }

    return 1;
}

=head1 SEE ALSO

L<MooseX::Transactional>,
L<Moose>, 
L<Variable::Magic>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
