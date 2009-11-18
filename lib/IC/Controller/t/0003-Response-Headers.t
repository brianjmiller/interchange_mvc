#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 35);

my $class = 'IC::Controller::Response::Headers';
BEGIN: {
	require_ok($class);
}

my $headers = $class->new;
isa_ok($headers, $class);

diag('Basic interface tests');
my %map = $headers->header_mapping;
is_deeply(
	\%map,
	{qw(
		status			Status
		content_type	Content-Type
		content_disposition	Content-Disposition
		location		Location
		target_window	Target-Window
	)},
	'header_mapping() maps methods to header names properly',
);

my %values = (
	status			=> '200 OK',
	content_type	=> 'text/html charset="utf-8"',
	content_disposition => 'attachment; filename="foo.txt"',
	location		=> 'http://www.endpoint.com',
	target_window	=> 'foo',
);

# Per test function, we need to:
# 1. Verify that no value exists in the corresponding header, first.
# 2. Verify setting a value through the method
# 3. Verify corresponding header receives value
# 4. Verify delete of value
# 5. Verify delete removes the corresponding header
my @tests = (
	'raw header is empty',
	'value set',
	'raw header set',
	'value delete',
	'raw header removed',
);
for my $test_function (keys %map) {
	my $sub = $headers->can( $test_function );
	if (! $sub) {
		fail($test_function . "(): $_")
			for @tests
		;
		next;
	}
	ok(
		!exists($headers->raw->{$map{$test_function}}),
		$test_function . "(): $tests[0]",
	);
	$headers->$sub( $values{$test_function} );
	cmp_ok(
		$headers->$sub(),
		'eq',
		$values{$test_function},
		$test_function . "(): $tests[1]",
	);
	cmp_ok(
		$headers->raw->{$map{$test_function}},
		'eq',
		$values{$test_function},
		$test_function . "(): $tests[2]",
	);
	$headers->$sub( undef );
	ok(
		!defined($headers->$sub()),
		$test_function . "(): $tests[3]",
	);
	ok(
		!exists($headers->raw->{$map{$test_function}}),
		$test_function . "(): $tests[4]",
	);
}

# Really simple cookie test, when cookie system gets overhauld,
# these tests will be more awesome. But currently these cookies aren't
# put in the header string till GlobalSub/mvc_dispatch.sub
my $cookie_ref = {
    name   => 'cookie_name',
    value  => 'cookie_value',
};

$headers->set_cookie($cookie_ref),
is_deeply(
    $headers->cookies,
	{
        cookie_name => {
            value => 'cookie_value',
		}
	},
    'set_cookie($cookie_info): verify cookie structure.'
);

diag('Testing header() result formatting, order, etc.');
@tests = (
	'status/content-type only',
	'main headers',
	'arbitrary headers',
);
# Note that the order of these is significant, as the headers returned by
# headers() both in list and scalar context should occur in a specific
# order.
my @header_sources = (
	[
		[ 'Status', '200 OK', ],
		[ 'Content-Type', 'text/html', ],
	],
	[
		[ 'Status', '302 Moved', ],
		[ 'Location', 'http://www.endpoint.com', ],
		[ 'Content-Type', 'text/html', ],
		[ 'Content-Disposition', 'inline', ],
	],
	[
		[ 'Status', '200 OK', ],
		[ 'Content-Type', 'text/html', ],
		[ 'X-Foo', 'foo', ],
		[ 'X-Monkey', 'monkey', ],
	],
);
for my $source (@header_sources) {
	my $test_name = shift @tests;
	$headers->raw( {} );
	$headers->raw->{$_->[0]} = $_->[1]
		for @$source
	;
	my @output = $headers->headers;
	my @expected = map { "$_->[0]: $_->[1]" } @$source;
	is_deeply(
		\@output,
		\@expected,
		"$test_name: headers() as array",
	);
	my $output = $headers->headers;
	cmp_ok(
		$output,
		'eq',
		join("\r\n", @expected),
		"$test_name: headers() as scalar",
	);
}

