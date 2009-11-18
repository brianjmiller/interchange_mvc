#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More ( tests => 31 );

my $class = 'IC::Controller::Route';
my $route_objects = $class . '::Object';

BEGIN: {
	require_ok( $class );
	require_ok( $route_objects );
};

diag('verifying basic object behaviors');
my $route = $class->new( name => 'test', controllers => [qw(a b c)] );
isa_ok(
	$route,
	$class,
);

cmp_ok(
	$route->name,
	'eq',
	'test',
	'name property',
);

is_deeply(
	$route->controllers,
	[qw( a b c )],
	'controllers property',
);

is_deeply(
	$route->routes,
	[],
	'routes property (empty list)',
);

my %foo_params = (
	controller => 'foo',
	action => 'foo',
);

my $foo_route = $route_objects->new( %foo_params, pattern => 'foo', controllers => $route->controllers, );
cmp_ok(
	$route->add_route( $foo_route ),
	'==',
	1,
	'routes (one item added)',
);

is_deeply(
	$route->routes,
	[ $foo_route ],
	'routes content (one item)',
);

my %pooh_params = (
	controller => 'pooh',
	action => 'pooh',
);

cmp_ok(
	$route->route( pattern => 'pooh', %pooh_params, ),
	'==',
	2,
	'routes (second item added)',
);

my $pooh_route = $route_objects->new( %pooh_params, pattern => 'pooh', controllers => $route->controllers, );
is_deeply(
	$route->routes,
	[ $foo_route, $pooh_route, ],
	'routes content (two items)',
);

is_deeply(
	$route->parse_path( 'foo', ),
	\%foo_params,
	'parse_path: first item',
);

is_deeply(
	$route->parse_path( 'pooh', ),
	\%pooh_params,
	'parse_path: second item',
);

ok(
	! defined( $route->parse_path( 'bogus' ) ),
	'parse_path: no match',
);

cmp_ok(
	$route->generate_path( %foo_params ),
	'eq',
	'foo',
	'generate_path: first item',
);

cmp_ok(
	$route->generate_path( %pooh_params ),
	'eq',
	'pooh',
	'generate_path: second item',
);

ok(
	! defined($route->generate_path( controller => 'bogus', action => 'noexist', )),
	'generate_path: no match',
);

diag('verifying interaction with IC::Controller');
package Bogus::Foo;
use IC::Controller;
use base qw(IC::Controller);
__PACKAGE__->registered_name( 'foo' );
1;
package Bogus::Bar;
use base qw(IC::Controller);
__PACKAGE__->registered_name( 'bar' );
1;
package main;

my $controller_list = [qw( bar foo )];
$route = $class->new( name => 'package_test' );
is_deeply(
	$route->controllers,
	$controller_list,
	'controllers defaults to known list from IC::Controllers',
);

diag('verifying package dispatching behaviors');
package Bogus::RouteA;
use base qw(IC::Controller::Route);
1;
package Bogus::RouteB;
use base qw(IC::Controller::Route);
1;
package main;

my $route_a_singleton = Bogus::RouteA->instantiate_package_singleton(
	controllers => [qw( 1 2 3 )],
);

cmp_ok(
	$route_a_singleton->name,
	'eq',
	'Bogus::RouteA',
	'instantiate_singleton: default name',
);

is_deeply(
	$route_a_singleton->controllers,
	[qw( 1 2 3 )],
	'instantiate_singleton: specified controllers',
);

cmp_ok(
	Bogus::RouteA->route( pattern => 'route_a/:controller/:action', ),
	'==',
	1,
	'package singleton: route',
);

cmp_ok(
	Bogus::RouteA->generate_path( controller => 1, action => 'taste', ),
	'eq',
	'route_a/1/taste',
	'package singleton: generate_path',
);

is_deeply(
	Bogus::RouteA->parse_path( 'route_a/2/smell' ),
	{ controller => 2, action => 'smell', },
	'package singleton: parse_path',
);

cmp_ok(
	Bogus::RouteB->route( pattern => 'route_b/:controller/:action', ),
	'==',
	1,
	'package singleton auto-instantiation via route method',
);

cmp_ok(
	Bogus::RouteB->generate_path( controller => 'foo', action => 'bar' ),
	'eq',
	'route_b/foo/bar',
	'package singleton (auto-instantiated): generate_path (with default controllers)',
);

is_deeply(
	Bogus::RouteB->parse_path( 'route_b/bar/foo' ),
	{ controller => 'bar', action => 'foo', },
	'package singleton (auto-instantiated): parse_path (with default controllers)',
);

# flesh out other dispatched methods
cmp_ok(
	Bogus::RouteA->add_route( $route_objects->new( pattern => 'blahblahblah', controller => 'blah', action => 'blah', ) ),
	'==',
	2,
	'package singleton: add_route dispatch',
);

Bogus::RouteA->clear;
cmp_ok(
	scalar @{$route_a_singleton->routes},
	'==',
	0,
	'package singleton: clear dispatch',
);

diag('canonize_path() tests');
my $test_path = 'foo/bar/bah';
cmp_ok(
	$class->canonize_path( $test_path ),
	'eq',
	$test_path,
	'canonize_path(): identity',
);

cmp_ok(
	$class->canonize_path( "  /  / / //$test_path" ),
	'eq',
	$test_path,
	'canonize_path(): leading junk stripped',
);

cmp_ok(
	$class->canonize_path( "$test_path/ /  // ///   " ),
	'eq',
	$test_path,
	'canonize_path(): trailing junk stripped',
);

cmp_ok(
	$class->canonize_path( "/$test_path/" ),
	'eq',
	$test_path,
	'canonize_path(): leading and trailing junk stripped',
);

