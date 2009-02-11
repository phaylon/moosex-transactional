#!/usr/bin/env perl
use strict;
use lib qw( t/lib );

use Scalar::Util    qw( refaddr );
use Test::Most      tests => 22;

use aliased 'MooseX::Transactional::Test::Hooks';
use aliased 'MooseX::Transactional::Test::Placebo';

use MooseX::Transactional::Util qw( transaction );

my $placebo = Placebo->new;
is ref(my $obj = Hooks->new(foo => 17)), Hooks, 'creation';
is $obj->foo, 17, 'value is correct after construction';

transaction {
    $placebo->step(1);
    $obj->foo(23);
    is $obj->foo, 23, 'value is correct after change in transaction';
};
is $obj->foo, 23, 'value is correct after successful transaction';
is_deeply $placebo->values, [1], 'placebo object not affected';

is_deeply $obj->call_order, { TRANSACTION => [["$obj", 1]], COMMIT => [["$obj", 2]] },
    'hook method call order is correct';
is_deeply $obj->call_value, { 
    TRANSACTION => [[$obj, { foo => 17 }]],
    COMMIT      => [[$obj, { foo => 17 }]],
}, 'values passed to hook methods were correct';

my $placebo2 = Placebo->new;
my ($obj1, $obj2, $obj3) = map { Hooks->new(foo => $_) } 8 .. 10;
is $obj1->foo, 8, 'first object has correct value after creation';
is $obj2->foo, 9, 'second object has correct value after creation';
is $obj3->foo, 10, 'third object has correct value after creation';

transaction {
    $obj2->foo(19);
    $placebo2->step(1);
    
    transaction {
        $placebo2->step(2);
        $obj1->foo(18);

        dies_ok {

            transaction {
                $placebo2->step(3);

                transaction {
                    $placebo2->step(4);
                    $obj3->foo(20);
                    $placebo2->step(5);
                };
                die 'on purpose';
            };

        } 'forced death';
        like $@, qr/on purpose/, 'correct error thrown';
    };

    $placebo2->step(6);
};

is $obj1->foo, 18, 'first object has correct value after transactions';
is $obj2->foo, 19, 'second object has correct value after transactions';
is $obj3->foo, 10, 'third object has correct value after transactions';
is_deeply $placebo2->values, [1 .. 6], 'placebo object not affected';

sub by_addr { refaddr $a cmp refaddr $b }

my @two_counts   = (8, 9);
my %two_commit   = map { ($_ => shift(@two_counts)) } sort by_addr $obj3, $obj1;

my @three_counts = (10, 11, 12);
my %three_commit = map { ($_ => shift(@three_counts)) } sort by_addr $obj3, $obj2, $obj1;

is_deeply $obj1->call_order, {
    TRANSACTION => [
        ["$obj1", 4],
    ],
    COMMIT => [
        ["$obj1", $two_commit{ $obj1 }],
        ["$obj1", $three_commit{ $obj1 }],
    ],
}, 'call order for first object was correct';

is_deeply $obj1->call_value, {
    TRANSACTION => [
        [$obj1, { foo => 8 }],
    ],
    COMMIT => [
        [$obj1, { foo => 8 }],
        [$obj1, { foo => 8 }],
    ],
}, 'call values for first object were correct';

is_deeply $obj2->call_order, {
    TRANSACTION => [
        ["$obj2", 3],
    ],
    COMMIT => [
        ["$obj2", $three_commit{ $obj2 }],
    ],
}, 'call order for second object was correct';

is_deeply $obj2->call_value, {
    TRANSACTION => [
        [$obj2, { foo => 9 }],
    ],
    COMMIT => [
        [$obj2, { foo => 9 }],
    ],
}, 'call values for second object were correct';

is_deeply $obj3->call_order, {
    TRANSACTION => [
        ["$obj3", 5],
    ],
    COMMIT => [
        ["$obj3", 6],
        ["$obj3", $two_commit{ $obj3 }],
        ["$obj3", $three_commit{ $obj3 }],
    ],
    ROLLBACK => [
        ["$obj3", 7],
    ],
}, 'call order for third object was correct';

is_deeply $obj3->call_value, {
    TRANSACTION => [
        [$obj3, { foo => 10 }],
    ],
    COMMIT => [
        [$obj3, { foo => 10 }],
        [$obj3, { foo => 10 }],
        [$obj3, { foo => 10 }],
    ],
    ROLLBACK => [
        [$obj3, { foo => 10 }],
    ],
}, 'call values for third object were correct';



