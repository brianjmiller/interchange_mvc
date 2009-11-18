#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 7);

my $class = 'IC::Controller::Response';
BEGIN: {
	require_ok( $class );
}

my $response = $class->new;
isa_ok(
	$response,
	$class,
);

isa_ok(
	$response->headers,
	"${class}::Headers",
);

ok(
	!defined($response->buffer),
	'buffer() is undefined by default',
);

my $scalar = 'I am a scalar';
$response->buffer( \$scalar );
my $test = 'buffer() set is a SCALAR ref with correct value';
if (ref $response->buffer eq 'SCALAR' ) {
	cmp_ok(
		${ $response->buffer },
		'eq',
		$scalar,
		$test,
	);
}
else {
	fail($test);
}

my $scalar2 = 'I am also a scalar';
$response->buffer( $scalar2 );
$test = 'buffer() set with simple scalar is still a reference';
if (ref $response->buffer eq 'SCALAR' ) {
	cmp_ok(
		${ $response->buffer },
		'eq',
		$scalar2,
		$test,
	);
}
else {
	fail($test);
}

$response->buffer( undef );
ok(
	!defined($response->buffer),
	'buffer(undef) clears buffer',
);

