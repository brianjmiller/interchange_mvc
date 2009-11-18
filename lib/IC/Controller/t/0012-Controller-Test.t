#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More tests => 32;

package Foo::Route;
use IC::Controller::Route;
use base qw/IC::Controller::Route/;
1;

package Foo::Route::NoParse;
sub generate_path {
    return;
}
1;

package Foo::Route::NoGenerate;
sub parse_path {
    return;
}
1;

package Foo::Controller;
use IC::Controller;
use Scalar::Util qw/blessed/;
use base qw/IC::Controller/;
BEGIN {
    __PACKAGE__->registered_name('foo');
}

sub simple_action {
    my $self = shift;
    $self->response->headers->status('200 ok');
    $self->response->headers->content_type('text/plain');
    $self->response->buffer(
        join(
            "\n",
            map {
                my $val = $self->parameters->{$_};
                "$_ = "
                . (blessed($val) || ref($val) || $val);
            }
            sort { $a cmp $b }
            keys %{ $self->parameters }
        )
    );
    return;
}

sub redirect_action {
    # TODO: this will ultimate generate a redirect response of some sort,
    # and we'll need a test case that verifies the behavior of redirect_ok().
}

1;

package main;

my $module;
my $route_module;
BEGIN {
    $module = 'IC::Controller::Test';
    $route_module = 'IC::Controller::Route::Test';
    use_ok($module);
}

is(
    routes(),
    $route_module,
    'routes() default',
);

my $alt_route = 'Foo::Route';
eval { routes($alt_route) };
is(
    routes(),
    $alt_route,
    'routes() set/get',
);

eval { routes("$alt_route\::NoParse") };
cmp_ok(
    $@,
    '=~',
    qr/invalid route/i,
    'routes() set throws exception if new value cannot parse_path()',
);

eval { routes("$alt_route\::NoGenerate") };
cmp_ok(
    $@,
    '=~',
    qr/invalid route/i,
    'routes() set throws exception if new value cannot generate_path()',
);

is(
    routes(),
    $alt_route,
    'routes() unchanged by exception cases',
);

routes(undef);
is(
    routes(),
    $route_module,
    'routes() default restored by set undef',
);

ok(
    !defined(controller()),
    'controller() undefined by default',
);

my $controller = 'Foo::Controller';
controller($controller);
is(
    controller(),
    $controller,
    'controller() set/get',
);

controller(undef);
ok(
    !defined(controller()),
    'controller() set/get undef',
);

eval {controller($controller->registered_name)};
is(
    controller(),
    $controller,
    'controller() set/get using registered_name',
);

eval { controller('pinky ponky pong gong') };
cmp_ok(
    $@,
    '=~',
    qr/invalid controller/i,
    'controller() set throws exception on invalid input',
);

ok(
    !defined(response()),
    'reponse() undef by default',
);

my $response = IC::Controller::Response->new;
response($response);
cmp_ok(
    response(),
    '==',
    $response,
    'response() set/get',
);

response(undef);
ok(
    !defined(response()),
    'response() set undef',
);

eval { response('bonkybonk') };
cmp_ok(
    $@,
    '=~',
    qr/invalid response/i,
    'response() set throws exception if not response object',
);

response(undef);
ok(
    !defined(content()),
    'content() undef if response() undef',
);

ok(
    !defined(headers()),
    'headers() undef if response() undef',
);

response(IC::Controller::Response->new());
response()->headers()->status('200 OK');

cmp_ok(
    headers(),
    '==',
    response()->headers(),
    'headers() accesses response()->headers()',
);

ok(
    !defined(content()),
    'content() undef if response->buffer unset',
);

response()->buffer( \'some result content' );
is(
    content(),
    'some result content',
    'content() accesses response()->buffer when buffer is set',
);

eval { request() };
cmp_ok(
    $@,
    '=~',
    qr/specify an action/i,
    'request() throws exception without action',
);

ok(
    !defined(response()),
    'response() unset by request() call',
);

eval { request( action => 'blah', method => 'blah' ) };
cmp_ok(
    $@,
    '=~',
    qr/invalid method/i,
    'request() throws exception on invalid request method',
);

controller(undef);
eval {
    request(
        action => 'blah',
        method => 'get',
    );
};
cmp_ok(
    $@,
    '=~',
    qr/no controller/i,
    'request() throws exception without controller set',
);

controller('foo');
eval {
    request(
        action  => 'simple_action',
        method  => 'get',
        parameters => {
            a => 1,
            b => 2,
        },
    );
};

diag("Error in request(): $@") if $@;
isa_ok(
    response(),
    'IC::Controller::Response',
);

is(
    headers()->status(),
    '200 ok',
    'request() properly set response() object',
);

is(
    content(),
    "a = 1\naction = simple_action\nb = 2\ncontroller = foo\nmethod = get",
    'request() properly received parameters',
);

# Unfortunately, we cannot really test failures of these functions, since
# they wrap Test::More functions.  But we can at least verify that they match
# in the positive case.
header_ok('Content-Type', 'header_ok() no value check');
header_ok('Content-Type', 'header_ok() value check', 'text/plain');

content_cmp_ok(
   '=~',
   qr/controller...foo/,
   'content_cmp_ok() general content regex check', 
);

status_cmp_ok(
    '=~',
    qr/\b200\b/,
    'status_cmp_ok() general status line regex check',
);

