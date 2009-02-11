#!/usr/bin/env perl
use strict;
use inc::Module::Install;

name            'MooseX-Transactional';
author          "Robert 'phaylon' Sedlacek";
license         'perl';
all_from        'lib/MooseX/Transactional.pm';

test_requires   'Test::Most',                   '0.86';
requires        'Moose',                        '0.65';
requires        'MooseX::Method::Signatures',   '0.06';
requires        'MooseX::AttributeHelpers',     '0.14';
requires        'MooseX::Types',                '0.08';
requires        'MooseX::Types::Structured',    '0.07';
requires        'Variable::Magic',              '0.27';
requires        'Carp',                         '1.08';
requires        'Carp::Clan',                   '6.00';
requires        'aliased',                      '0.22';
requires        'namespace::clean',             '0.09';

WriteAll;
