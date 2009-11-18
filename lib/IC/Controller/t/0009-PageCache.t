#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use FindBin ();
use lib "$FindBin::Bin/0009-PageCache";

use Test::More tests => 13;
use Controllers;

my $class;
BEGIN {
    $class = 'IC::Controller::PageCache';
    use_ok( $class );
    eval 'use Controllers';
    eval 'use CacheHandlers';
}

my $c1 = 'Test::Controllers::Foo';
my $c2 = 'Test::Controllers::Bar';
my $cname1 = $c1->registered_name;
my $cname2 = $c2->registered_name;
my $r1 = 'Test::Route::One';
my $r2 = 'Test::Route::Two';
my $prefix1 = $r1->prefix;
my $prefix2 = $r2->prefix;
my $magic1 = "$prefix1/specific";
my $magic2 = "$prefix2/specific";
my $cache1 = 'Test::CacheHandlers::A';
my $cache2 = 'Test::CacheHandlers::B';

# set $c1 instance as the bound controller, with $r1 as its route_handler
my $controller1 = $c1->new( route_handler => $r1 );
IC::Controller::HelperBase->bind_to_controller( $controller1 );

# set $c2 instance to use $r2 as its route_handler.
my $controller2 = $c2->new( route_handler => $r2 );

# simple check; bound controller used, and its route handler
cmp_ok(
    $class->determine_cache_key(
        parameters => {
            action => 'test',
        },
    ),
    'eq',
    "$prefix1/$cname1/test",
    'determine_cache_key() bound route handler and controller, basic route'
);

# slightly less simple check; bound controller used for route, but alternate
# controller for actual link
cmp_ok(
    $class->determine_cache_key(
        parameters => {
            controller  => $cname2,
            action      => 'foo',
        },
    ),
    'eq',
    "$prefix1/$cname2/foo",
    'determine_cache_key() bound route handler, specified controller name, basic route',
);

# same kind of check, but provided controller as object rather than name
cmp_ok(
    $class->determine_cache_key(
        parameters => {
            controller  => $controller2,
            action      => 'pooh',
        },
    ),
    'eq',
    "$prefix1/$cname2/pooh",
    'determine_cache_key() bound route_handler, specified controller instance, basic route',
);

# similar check but reversed; default controller, specified route handler
cmp_ok(
    $class->determine_cache_key(
        route_handler   => $r2,
        parameters      => {
            action      => 'blah',
        },
    ),
    'eq',
    "$prefix2/$cname1/blah",
    'determine_cache_key() specified route_handler, bound controller, basic route',
);

# specified route and controller by name
cmp_ok(
    $class->determine_cache_key(
        route_handler   => $r2,
        parameters      => {
            controller  => $cname2,
            action      => 'moo',
        },
    ),
    'eq',
    "$prefix2/$cname2/moo",
    'determine_cache_key() route_handler and controller specified, basic route',
);

# magic route for canonical URL demonstration
cmp_ok(
    $class->determine_cache_key(
        parameters  => $r1->parse_path( "$prefix1/$cname1/special" ),
    ),
    'eq',
    $magic1,
    'determine_cache_key() canonical route demonstration',
);

# Cache stuff; ensure that the set_cache and get_cache work properly with
# the appropriate cache handler.
SKIP: {
    my ($current_action, $current_key, $params);
    $current_action = 'some_action';
    # set up our standard page parameters
    $params = { action => $current_action };
    $current_key = $class->determine_cache_key( parameters => $params );

    skip('No current key to use as expected key for get/set tests', 6)
        unless defined $current_key and $current_key =~ /\S/
    ;

    # set up our expected results from get operations.
    my ($expected1, $expected2) = map { $_->identifier() . ": $current_key" } ( $cache1, $cache2 );
    
    # the base class (IC::Controller::PageCache) does not provide cache support, so this
    # should throw an exception.
    eval { $class->set_cache( parameters => $params ) };
    ok( $@, 'set_cache() throws exception if no set() defined' );

    # this should similarly throw an exception
    eval { $class->get_cache( parameters => $params ) };
    ok( $@, 'get_cache() throws exception if no get() defined' );

    # this should return the expected result of cache1, via local set/get implementation
    cmp_ok(
        eval { $cache1->set_cache( parameters => $params ) },
        'eq',
        $cache1->identifier(),
        'set_cache() uses invocant set() method',
    );
    cmp_ok(
        eval { $cache1->get_cache( parameters => $params ) },
        'eq',
        $expected1,
        'get_cache() uses invocant get() method',
    );

    # this should give expected result of cache2, do to explicit specification of handler
    cmp_ok(
        eval { $cache1->set_cache( parameters => $params, cache_handler => $cache2 ) },
        'eq',
        $cache2->identifier(),
        'set_cache() uses cache_handler set() when provided',
    );
    cmp_ok(
        eval { $cache1->get_cache( parameters => $params, cache_handler => $cache2 ) },
        'eq',
        $expected2,
        'get_cache() uses cache_handler get() when provided',
    );
}

