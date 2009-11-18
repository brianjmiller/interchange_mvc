#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use EndPoint::Config;

use Test::More (tests => 29);

use IC::Controller;
use IC::Controller::Route;
use IC::Controller::Route::Helper;
use File::Find;

ok(
    exists($main::{url}),
    'url() exported properly',
);

package Bogus::Controller;
use Moose;
extends qw(IC::Controller);
__PACKAGE__->registered_name('bogus');
1;

package Bogus::Route;
use base qw(IC::Controller::Route);
__PACKAGE__->route(
    pattern => 'post/:controller/:action/:parameter',
    method  => 'post',
);
__PACKAGE__->route(
    pattern => ':controller/:action/:parameter',
);
__PACKAGE__->route(
    pattern => 'post/:controller/:action',
    method  => 'post',
);
__PACKAGE__->route(
    pattern => ':controller/:action',
);
1;

package main;

IC::Controller::Route->route(
    pattern => 'default',
    controller => 'bogus',
    action => 'test',
);

my $router = IC::Controller::Route->new;
$router->route(
    pattern => 'override',
    controller => 'bogus',
    action => 'test',
);

my $controller = Bogus::Controller->new( route_handler => 'Bogus::Route', );
$Vend::Cfg->{VendURL} = 'http://foo/ic/foo';
$Vend::Cfg->{SecureURL} = 'https://foo/ic/foo';
my $secure;

for my $url_base ($Vend::Cfg->{VendURL}, $Vend::Cfg->{SecureURL}) {
    IC::Controller::HelperBase->bind_to_controller( $controller );

    cmp_ok(
        url(
            controller => 'bogus',
            action => 'test',
            no_session => 1,
            secure => $secure,
        ),
        'eq',
        $url_base . '/bogus/test',
        'url(): basic route with controller specified',
    );

    cmp_ok(
        url(
            controller  => 'bogus',
            action      => 'test',
            no_session  => 1,
            secure      => $secure,
            method      => 'post',
        ),
        'eq',
        $url_base . '/post/bogus/test',
        'url(): post route with controller specified (adheres to method specified)',
    );

    cmp_ok(
        url(
            controller  => 'bogus',
            action      => 'test',
            no_session  => 1,
            secure      => $secure,
            anchor      => 'anchor_test',
        ),
        'eq',
        $url_base . '/bogus/test#anchor_test',
        'url(): basic route with anchor support',
    );

    cmp_ok(
        url(
            action => 'test2',
            no_session => 1,
            secure => $secure,
        ),
        'eq',
        $url_base . '/bogus/test2',
        'url(): basic route with controller defaulting to controller()->registered_name',
    );
    
    cmp_ok(
        url(
            action => 'test3',
            parameters => { parameter => 'foo', },
            get => {
                a => 1,
                b => 2,
            },
            secure => $secure,
            no_session => 1,
        ),
        'eq',
        $url_base . '/bogus/test3/foo?a=1&b=2',
        'url(): route with get variables',
    );

    eval {
        url(
            action => 'blahblahblah',
            controller => 'i_do_not_exist',
            parameters => { blah => 'boo', flah => 'foo', mlah => 'moo', },
            no_session => 1,
            secure => $secure,
        );
    };

    ok(
        $@,
        'url() with bad routing parameters throws exception',
    );

    cmp_ok(
        url(
            controller => 'bogus',
            action => 'test',
            route_handler => $router,
            no_session => 1,
            secure => $secure,
        ),
        'eq',
        $url_base . '/override',
        'url() with route_handler set',
    );

    IC::Controller::HelperBase->bind_to_controller( undef );
    cmp_ok(
        url(
            controller => 'bogus',
            action => 'test',
            no_session => 1,
            secure => $secure,
        ),
        'eq',
        $url_base . '/default',
        'url() with no controller defaults to IC::Controller::Route for routing',
    );

    cmp_ok(
        url(
            href => 'foo',
            controller => 'bad',
            action => 'bad',
            no_session => 1,
            secure => $secure,
        ),
        'eq',
        $url_base . '/foo',
        'url() href overrides routing',
    );

    $secure++;
}

my $external = 'http://www.google.com';
cmp_ok(
    url( href => $external ),
    'eq',
    $external,
    'url() full URLs pass through unchanged',
);

SKIP: {
    eval { use IC::Controller::Route::Binding; };
    skip('Unable to load IC::Controller::Route::Binding package', 6) if $@;

    my $base = $Vend::Cfg->{VendURL};
    
    IC::Controller::HelperBase->bind_to_controller( $controller );
    my $route_handler = undef;
    my $suffix = ' (default routing)';
    
    while (1) {
        my $binding = IC::Controller::Route::Binding->new;
        $binding->controller( 'bogus' );
        $binding->action( 'action' );
        $binding->url_names( [qw( parameter )] );
        $binding->route_handler( $route_handler );
        $binding->controller_parameters->{parameter} = 'foo';
        cmp_ok(
            url( binding => $binding, no_session => 1,),
            'eq',
            $base . '/bogus/action/foo',
            'url(): binding controller information and parameters' . $suffix,
        );
        
        $binding->parameters( { a => 'a' } );
        cmp_ok(
            url( binding => $binding, no_session => 1, ),
            'eq',
            $base . '/bogus/action/foo?a=a',
            'url(): binding controller information, url parameters, get parameters' . $suffix,
        );

        $binding->controller( undef );
        $binding->action( undef );
        $binding->url_names( [] );
        $binding->controller_parameters( {} );
        $binding->href( 'some_page' );
        cmp_ok(
            url( binding => $binding, no_session => 1, ),
            'eq',
            $base . '/some_page?a=a',
            'url(): binding with href and get parameters' . $suffix,
        );

        last if defined $route_handler;
        $route_handler = 'Bogus::Route';
        IC::Controller::HelperBase->bind_to_controller( undef );
        $suffix = ' (routing override)';
    }
}


# cache_helper tests

ok(
    exists($main::{cache_helper}),
    'cache_helper() exported properly',
);

like(cache_helper(),'/x=\d+/','cache_helper() returns a sensible value');

#########################################
ok (1,"Finished tests for $0");
