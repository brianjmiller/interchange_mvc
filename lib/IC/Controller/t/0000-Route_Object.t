#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use EndPoint::Config;
use Test::More (tests => 59);

my $class = 'IC::Controller::Route::Object';
BEGIN: {
	require_ok($class);
}

my $obj = $class->new(
	pattern 	=> 'foo',
	controller 	=> 'test',
	action		=> 'faux',
);

isa_ok(
	$obj,
	$class,
);

cmp_ok(
	$obj->pattern,
	'eq',
	'foo',
	'static path: pattern'
);

cmp_ok(
	scalar @{ $obj->components },
	'==',
	1,
	'static path: components'
);

cmp_ok(
	$obj->generate_path( controller => 'test', action => $obj->action, ),
	'eq',
	'foo',
	'static path: path generation if action specified',
);

ok(
    ! defined $obj->generate_path( controller => 'test', ),
    'static path: path generation undefined if no action specified',  
);

$obj->defaults({ action => $obj->action });
cmp_ok(
    $obj->generate_path( controller => 'test', ),
    'eq',
    'foo',
    'static path: path generation with default action',
);

ok(
	! defined $obj->generate_path( controller => 'foo', ),
	'static path: path generation (undefined)',
);

ok(
	! defined $obj->parse_path( 'blah' ),
	'static path: path parse (undefined)',
);

is_deeply(
	$obj->parse_path( 'foo' ),
	{ controller => 'test', action => 'faux', },
	'static path: path parse',
);

$obj->controllers( [ qw(a b c) ] );
is_deeply(
	$obj->controllers,
	[qw( a b c )],
	'controllers: set/get',
);

$obj->controller( undef );
$obj->pattern( ':controller' );
cmp_ok(
	scalar @{ $obj->components },
	'==',
	1,
	'simple path: components',
);

ok(
	! defined $obj->generate_path( controller => 'test', ),
	'simple path: path generation (undefined)',
);

cmp_ok(
	$obj->generate_path( controller => 'a', ),
	'eq',
	'a',
	'simple path: path generation',
);

cmp_ok(
	$obj->generate_path( controller => 'b', ),
	'eq',
	'b',
	'simple path: path generation',
);

cmp_ok(
	$obj->generate_path( controller => 'c', ),
	'eq',
	'c',
	'simple path: path generation',
);

ok(
	! defined $obj->parse_path( 'd' ),
	'simple path: path parse (undefined)',
);

is_deeply(
	$obj->parse_path( 'a' ),
	{ controller => 'a', action => 'faux', },
	'simple path: path parse',
);

is_deeply(
	$obj->parse_path( 'b' ),
	{ controller => 'b', action => 'faux', },
	'simple path: path parse',
);

is_deeply(
	$obj->parse_path( 'c' ),
	{ controller => 'c', action => 'faux', },
);

diag('Checking for optional component operations');
$obj = $class->new(
	pattern => ':controller/:action/:id',
	defaults => {
		id => undef,
	},
	controllers => [qw(
		a b c
	)],
);

is_deeply(
	$obj->parse_path( 'a/test/1' ),
	{
		controller	=> 'a',
		action		=> 'test',
		id			=> 1,
	},
	'path with optionals: full parse',
);

is_deeply(
	$obj->parse_path( 'a/test' ),
	{
		controller	=> 'a',
		action		=> 'test',
		id			=> undef,
	},
	'path with optionals: parse with one default',
);

is_deeply(
	$obj->parse_path( 'b/test' ),
	{
		controller	=> 'b',
		action		=> 'test',
		id			=> undef,
	},
	'path with optionals: parse with one default (alternate controller)',
);

ok( !defined($obj->parse_path('b')), 'path with optionals: parse with no action is undefined');

ok( !defined($obj->parse_path('foo/test')), 'path with optionals: parse with unknown controller is undefined');

ok( !defined($obj->parse_path('a/test/1/foo')), 'path with extra segments: parse for unknown segments is undefined');

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', id => 1 ),
	'eq',
	'c/test/1',
	'path with options: full generation',
);

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', ),
	'eq',
	'c/test',
	'path with options: one default',
);

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', id => '' ),
	'eq',
	'c/test',
	'path with options: one parameter matches default',
);

diag('More advanced defaults/optionals');
$obj->defaults( { id => 1, action => 'a', } );
is_deeply(
	$obj->parse_path( 'c/test/2' ),
	{
		controller	=> 'c',
		action		=> 'test',
		id			=> 2,
	},
	'multi-optional path: parse fully-defined path',
);

is_deeply(
	$obj->parse_path( 'c/test' ),
	{
		controller	=> 'c',
		action		=> 'test',
		id			=> 1,
	},
	'multi-optional path: parse with one optional',
);

is_deeply(
	$obj->parse_path( 'c' ),
	{
		controller	=> 'c',
		action 		=> 'a',
		id			=> 1,
	},
	'multi-optional path: parse with all optionals',
);

ok( !defined($obj->parse_path( '' )), 'multi-optional path: empty path undefined' );

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', id => 'foo' ),
	'eq',
	'c/test/foo',
	'multi-optional path: generate fully-defined path',
);

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', ),
	'eq',
	'c/test',
	'multi-optional path: generate path with one default',
);

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'test', id => 1 ),
	'eq',
	'c/test',
	'multi-optional path: generate path with one parameter/default match',
);

cmp_ok(
	$obj->generate_path( controller => 'c', ),
	'eq',
	'c',
	'multi-optional path: generate path with all defaults',
);

cmp_ok(
	$obj->generate_path( controller => 'c', action => 'a', id => 1, ),
	'eq',
	'c',
	'multi-optional path: generate path with all parameter/default matches',
);

cmp_ok(
	$obj->generate_path( controller => 'c', id => 'foo', ),
	'eq',
	'c/a/foo',
	'multi-optional path: generate path with one dependent default overridden',
);

eval {
	$obj = $class->new(pattern => '*foo/blah',);
	$obj->generate_components;
};

ok( $@, 'array-based path: exception thrown if array is not final segment', );

$obj = $class->new( pattern => '*segments', controller => 'foo', action => 'bar', );
is_deeply(
	$obj->parse_path( '' ),
	{ controller => 'foo', action => 'bar', segments => [], },
	'array-based path: empty path',
);

is_deeply(
	$obj->parse_path( 'poo' ),
	{ controller => 'foo', action => 'bar', segments => [qw(poo)], },
	'array-based path: single segment',
);

is_deeply(
	$obj->parse_path( 'pooh/bear' ),
	{ controller => 'foo', action => 'bar', segments => [qw(pooh bear)], },
	'array-based path: two segments',
);

is_deeply(
	$obj->parse_path( 'pooh/bear/honey', ),
	{ controller => 'foo', action => 'bar', segments => [qw(pooh bear honey)], },
	'array-based path: three segments',
);

cmp_ok(
	$obj->generate_path( controller => 'foo', action => 'bar', ),
	'eq',
	'',
	'array-based path: generate empty path',
);

cmp_ok(
	$obj->generate_path( controller => 'foo', action => 'bar', segments => '1', ),
	'eq',
	'1',
	'array-based path: generate single-level path',
);

cmp_ok(
	$obj->generate_path( controller => 'foo', action => 'bar', segments => [1, 2, 3, 4], ),
	'eq',
	'1/2/3/4',
);

$obj = $class->new( pattern => ':a/_/:b', controller => 1, action => 1, defaults => { a => 'a', b => 'b', }, );
ok( !defined($obj->parse_path('_')), 'optionals/literal path: literal-only fails', );

is_deeply(
	$obj->parse_path( 'm/_/n', ),
	{ controller => 1, action => 1, a => 'm', b => 'n', },
	'optionals/literal path: full path',
);

is_deeply(
	$obj->parse_path( 'm/_', ),
	{ controller => 1, action => 1, a => 'm', b => 'b', },
	'optionals/literal path: second default',
);

ok( !defined($obj->parse_path('a')), 'optionals/literal path: param with no literal fails', );

cmp_ok(
	$obj->generate_path( controller => 1, action => 1, a => 1, b => 2, ),
	'eq',
	'1/_/2',
	'optionals/literal path: generate full path',
);

cmp_ok(
	$obj->generate_path( controller => 1, action => 1, a => 1, ),
	'eq',
	'1/_',
	'optionals/literal path: generate with one default still provides literal segment',
);

cmp_ok(
	$obj->generate_path( controller => 1, action => 1, ),
	'eq',
	'a/_',
	'optionals/literal path: generate with both defaults still provides first param and literal segment',
);

diag('verifying that method limiters work as intended');
$obj = $class->new(
    pattern => 'foo',
	controller => 'test',
	action => 'test',
	method => 'get',
);

cmp_ok(
	$obj->generate_path( controller => 'test', action => 'test', method => 'get', ),
	'eq',
	'foo',
	'method limits: matching method generates path',
);

is_deeply(
	$obj->parse_path( 'foo', 'get', ),
	{ controller => 'test', action => 'test', },
	'method limits: path parse with get',
);

is_deeply(
	$obj->parse_path( 'foo', ),
	{ controller => 'test', action => 'test', },
	'method limits: path parsing with get default',
);

ok(
	! defined( $obj->parse_path( 'foo', 'post', ) ),
	'method limits: path parsing with post undefined',
);

ok(
	! defined( $obj->generate_path( controller => 'test', action => 'test', method => 'post', ) ),
	'method limits: path generation with post undefined',
);


