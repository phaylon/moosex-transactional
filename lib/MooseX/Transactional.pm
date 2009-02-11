=head1 NAME

MooseX::Transactional - Transaction support for Moose objects

=cut

package MooseX::Transactional;
use strict;
use warnings;

use Moose ();
use Moose::Util::MetaRole;
use Moose::Exporter;

use aliased 'MooseX::Transactional::Role::Meta::Class', 'ClassMetaRole';

use namespace::clean;

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    also => [qw( Moose )],
);

=head1 SYNOPSIS

  package MyFoo;
  use MooseX::Transactional;
  
  has foo => (
      is        => 'rw',
      isa       => 'Str',
  );
  
  sub TRANSACTION {
      my ($self, $saved_data) = @_;
      printf "transaction start for %s\n", ref $self;
  }
  
  sub COMMIT {
      my ($self, $saved_data) = @_;
      printf "committing %s\n", ref $self;
  }
  
  sub ROLLBACK {
      my ($self, $saved_data) = @_;
      printf "rolling back %s\n", ref $self;
  }
  
  1;

And then later:

  #!/usr/bin/env perl
  use strict;
  use warnings;
  
  use MooseX::Transactional::Util qw( transaction );
  use MyFoo;
  
  my $foo = MyFoo->new(foo => 23);
  printf "before transaction: foo is now %s\n", $foo->foo;
  
  transaction {
      $foo->foo(17);
      printf "in transaction: foo is now %s\n", $foo->foo;
  };
  printf "after transaction: foo is now %s\n", $foo->foo;
  
  eval {
      transaction {
          $foo->foo(616);
          printf "in failing transaction: foo is now %s\n", $foo->foo;
          die "some error\n";
      };
  };
  printf "after failing transaction: foo is now %s\n", $foo->foo;
  
  __END__
  before transaction: foo is now 23
  transaction start for MyFoo
  in transaction: foo is now 17
  committing MyFoo
  after transaction: foo is now 17
  transaction start for MyFoo
  in failing transaction: foo is now 616
  rolling back MyFoo
  after failing transaction: foo is now 17

=head1 DESCRIPTION

Turns the importing class into a transactional object. You can create a new transaction
scope via L<MooseX::Transactional::Util/transaction>:

  use MooseX::Transactional::Util qw( transaction );
  
  my $foo = My::Transactional::Class->new;
  
  transaction {
      $foo->bar('baz');
      
      # other code...
  }

The block will be wrapped in an eval. If an error occured, all transactional objects
will be reset to their previous state and the error rethrown.

If the transaction was completed without error, the objects will be committed
and the associated stored data removed.

=head2 Transaction Hook Methods

Since you might want to allow transactional use of other resources (e.g. files or
other kinds of data) there are three method hooks provided that will be called:

=over

=item TRANSACTION( Object $self, HashRef $cloned_data )

Will be called when the object has been accessed and got bound to the transaction.

=item COMMIT( Object $self, HashRef $cloned_data )

This is called when the transaction has ended successfully.

=item ROLLBACK( Object $self, HashRef $cloned_data )

When an error occurred, this method will be called. This allows you to restore some
other kind of resource that you previously stored in the data hash reference.

=back

=head2 Nested Transactions

This module will manage a L<stack|MooseX::Transactional::Stack> that allows you to
nest your L<transaction|MooseX::Transactional::Util/transaction> scopes as you need 
them:

  my $foo = My::Transactional::Class->new(bar => 23);
  
  eval {
      transaction {
          $foo->bar(17);            # foo is now 17
  
          eval {
              transaction {
                  $foo->bar(777);   # foo is now 777
  
                  die "die";
              };
          };
  
          say $foo->bar;            # will say 17
          die "die";
      };
  };
  say $foo->bar;                    # will say 23

=head1 METHODS

=cut

=head2 init_meta

This method is provided for L<Moose::Exporter|Moose::Exporter/IMPORTING AND init_meta>.
It will initialise L<meta|Moose> for the class using C<MooseX::Transactional>. The role
L<MooseX::Transactional::Role::Meta::Class> will be applied to the consumer class' meta
class object.

You shouldn't worry about this method as a user.

=cut

sub init_meta {
    my ($self, %options) = @_;

    # make a _real_ class
    Moose->init_meta(%options);

    # add our meta class role to the importing class
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                   => $options{for_class},
        metaclass_roles             => [ClassMetaRole],
    );

    # caller expects meta class
    return $options{for_class}->meta;
}

=head1 CAVEATS

=over

=item *

A L<dclone|Storable/dclone> will be done on every L<fetch, store and delete magic|Variable::Magic>.

=item *

Only objects based on hash references are supported by now.

=back

=head1 SEE ALSO

L<MooseX::Transactional::Util>,
L<Moose>, 
L<Variable::Magic>, 
L<Storable>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
