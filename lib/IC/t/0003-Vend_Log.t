#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

package Foo::Log;
use base qw/IC::Log/;
use IC::Log::Base;

__PACKAGE__->set_logger( IC::Log::Base->new );

package IC::Log::Bogus;
sub new {
	return bless {}, shift;
}

package IC::Log::Class;
sub log {}

package Class::Log;
use base qw/IC::Log/;

package main;
use Test::More tests => 8;
#use Backcountry::Config use_libs => 1;
use IC::Log::Base;
use Scalar::Util qw/blessed/;

my ($class, $test1);
my $subclass = 'Foo::Log';
my $no_obj = 'Class::Log';

BEGIN {
	$class = 'IC::Log';
	use_ok($class);
}

$test1 = blessed($class->logger) || $class->logger;
is(
	$test1,
	'IC::Log::Interchange',
    'logger() default type',
);

isa_ok(
	$class->set_logger(IC::Log::Base->new),
	'IC::Log::Base',
);

$test1 = blessed( $subclass->logger ) || $subclass->logger;
is(
	$test1,
	'IC::Log::Base',
    'logger() set/get operations (set with object)',
);

isa_ok(
	$subclass->set_logger(IC::Log::Interchange->new),
	'IC::Log::Interchange',
);

$test1 = blessed( $class->logger ) || $class->logger;
is(
	$test1,
	'IC::Log::Base',
    'logger() set/get operations (different object)',
);

$test1 = blessed( $no_obj->logger('IC::Log::Class') )
	|| $no_obj->logger('IC::Log::Class');

is(
	$test1,
	'IC::Log::Class',
    'logger() set/get operations on a subclass',
);

eval { $class->set_logger(IC::Log::Bogus->new) };
ok(
	$@,
	q{set_logger properly died when log package->can('log') failed},
);
