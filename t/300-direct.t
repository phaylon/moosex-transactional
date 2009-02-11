#!/usr/bin/env perl
use strict;
use lib qw( t/lib );

use Test::Most tests => 7;

use aliased 'MooseX::Transactional::Test::Hooks';

use MooseX::Transactional::Util qw( transaction );

ok +(my $basic = Hooks->new(foo => 17)), 'transactional object can be created';
is $basic->{foo}, 17, 'direct access returns correct value';

my $inside;
transaction {
    $basic->{foo} = 23;

    dies_ok {
        transaction {
            $basic->{foo} = 77;
            $inside = $basic->{foo};
            die 'on purpose';
        };
    } 'forced death';
};

is $basic->foo, 23, 'correct value after transactions with direct access';
is $inside, 77, 'correct value inside of transactions';

is_deeply $basic->call_order, {
    TRANSACTION => [ ["$basic", 1], ["$basic", 2] ],
    ROLLBACK    => [ ["$basic", 3] ],
    COMMIT      => [ ["$basic", 4] ],
}, 'call order was correct';

is_deeply $basic->call_value, {
    TRANSACTION => [ [$basic, { foo => 17 }], [$basic, { foo => 23 }] ],
    ROLLBACK    => [ [$basic, { foo => 23 }] ],
    COMMIT      => [ [$basic, { foo => 17 }] ],
}, 'call values were correct';
