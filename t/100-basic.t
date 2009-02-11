#!/usr/bin/env perl
use strict;
use lib qw( t/lib );

use Test::Most tests => 15;

use aliased 'MooseX::Transactional::Test::Basic';
use aliased 'MooseX::Transactional::Test::Placebo';

use MooseX::Transactional::Util qw( transaction );

my $placebo = Placebo->new;
ok +(my $basic = Basic->new(foo => 17)), 'transactional object can be created';
$basic->foo(23);
is $basic->foo, 23, 'value is correct before transaction';
$placebo->step(1);

my $invalid_lines = 0;
dies_ok {
    transaction {
        $placebo->step(2);
        is $basic->foo, 23, 'value is still correct in transaction';
        $basic->foo(17);
        is $basic->foo, 17, 'value is correct after change in transaction';
        $placebo->step(3);
    };
    $placebo->step(4);
    is $basic->foo, 17, 'value was committed after successful transaction';

    transaction {
        $placebo->step(5);
        is $basic->foo, 17, 'value is still like before in new transaction';
        $basic->foo(616);
        is $basic->foo, 616, 'value is still correct after change in second transaction';
        $basic->baz(777);
        is_deeply $basic->bar, [777], 'internal push on array ref worked';
        is $basic->foo, 777, 'internal setting of attribute value worked';
        $placebo->step(6);
        die 'on purpose';
        $invalid_lines++;
    };
    $invalid_lines++;
} 'should die';
like $@, qr/on purpose/, 'thrown error was correct';
is $invalid_lines, 0, 'no invalid lines were called';
is $basic->foo, 17, 'value is rolled back to value after successful transaction';
ok not(exists $basic->{bar}), 'internal changes do not exist after rollback';

is_deeply $placebo->values, [1 .. 6], 'placebo object not affected';


