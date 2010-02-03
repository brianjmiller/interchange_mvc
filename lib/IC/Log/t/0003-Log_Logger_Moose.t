#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 16;

my ($class, $subclass, $global_class);
BEGIN {
    $class = 'IC::Log::Logger::Moose';
    $global_class = 'IC::Log';
    use_ok($class);
}

package Bogus::MooseLog;
use base ($class);
$subclass = __PACKAGE__;

package main;

my $obj = $class->new;

isa_ok(
    $obj,
    $class,
);

ok(
    !( $obj->has_logger ),
    'has_logger() not been explicitly set',
);

ok(
    !defined($obj->get_logger),
    'get_logger() attribute defaults to undef',
);

$obj->set_logger( undef );
ok(
    !defined($obj->get_logger),
    'get/set_logger() undef attribute',
);

ok(
    $obj->has_logger,
    'has_logger() with attribute unset',
);

my $logger = IC::Log::Base->new;
$obj->set_logger( $logger );
is(
    $obj->get_logger,
    $logger,
    'get/set_logger() type constraint allows IC::Log::Base object',
);

ok(
    $obj->has_logger,
    'has_logger() with attribute set',
);

$obj->set_logger( $global_class );
is(
    $obj->get_logger,
    $global_class,
    "get/set_logger() type constraint allows $global_class name",
);

eval { $obj->set_logger( 'foo' ) };
cmp_ok(
    $@,
    '=~',
    qr/ICLogger/,
    'get/set_logger() type constraint disallows garbage value',
);

$obj->set_logger( $logger );
$obj->set_logger( undef );
ok(
    !defined($obj->get_logger),
    'get/set_logger() undef clears attribute',
);

ok(
    $obj->has_logger,
    'has_logger() with attribute unset',
);

is(
    $obj->logger,
    $global_class->logger,
    'logger() base class default object',
);

$obj->set_logger( IC::Log::Base->new );
is(
    $obj->logger,
    $obj->get_logger,
    'logger() base class specific object',
);

$obj = $subclass->new;
is(
    $obj->logger,
    $global_class->logger,
    'logger() subclass default object',
);

$obj->set_logger( IC::Log::Base->new );
is(
    $obj->logger,
    $obj->get_logger,
    'logger() subclass specific object',
);

