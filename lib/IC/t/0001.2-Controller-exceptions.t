#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use Test::More tests => 22;
use Scalar::Util qw(blessed);
my ($class, $exception_class, $ok, $lib_path);
BEGIN {
    $lib_path = $1 . '/lib'
        if __FILE__ =~ m{(.+?)\.t$}
    ;
    eval 'use lib $lib_path' if defined $lib_path;
}


BEGIN {
    $class = 'IC::Controller';
    $exception_class = $class. '::Exception::Request';
    use_ok($class) && $ok++;
}

BAIL_OUT('Failed to use ' . $class) unless $ok;

my @exception_fields = qw(
    action
    cgi
    controller
    headers
    path
    path_params
    request_class
    route_handler
);

my ($ctl_ref, $ctl_str, $util_class, $handler_name, $handler_sub);
BEGIN {
    ($ctl_ref, $ctl_str, $util_class) = qw(AppWithRef AppWithString MVC2TestErrorHandler);
    use_ok($ctl_ref);
    use_ok($ctl_str);
}

$handler_name = 'my_handler';
my $token = "\*${util_class}::${handler_name}{CODE}";
$handler_sub = eval $token;
BAIL_OUT('Failed to use test controller classes!') unless $handler_sub;

cmp_ok( $ctl_ref->error_handler, '==', $handler_sub, 'error_handler() get/set coderef' );
cmp_ok( $ctl_str->error_handler, 'eq', $handler_name, 'error_handler() get/set string' );

# This should throw an exception due to type constraint
eval {
    $ctl_ref->error_handler( [] );
};
ok( $@, 'error_handler() set throws exception on invalid type' );
# Restore to previous state
$ctl_ref->error_handler($handler_sub);

{
    my $result = $ctl_ref->handle_error( 'some error' );
    $result = UNIVERSAL::isa($result, 'IC::Controller::Response') ? ${$result->buffer}  : undef;
    is($result, "handled error from $ctl_ref", 'handle_error() dispatching to error handler reference');
    
    $result = $ctl_str->handle_error( 'some other error' );
    $result = UNIVERSAL::isa($result, 'IC::Controller::Response') ? ${$result->buffer} : undef;
    is($result, "handled error from $ctl_str", 'handle_error() dispatching to error handler by name');

    $ctl_str->error_handler('some completely bogus method name');
    eval {
        $ctl_str->handle_error('yet another error');
    };
    ok( $@, 'handle_error() throws exception on bad handler method name' );
}

# Validate the process_request behavior to ensure:
# * the error handler receives an exception object
# * the exception object attributes are populated
my $new_handler = sub {
    my ($self, $error) = @_;
    return $error;
};
eval { $ctl_ref->error_handler($new_handler) };
SKIP: {
    my $tests = 12;
    skip('Unable to set error handler sub for end-to-end test', $tests)
        unless $ctl_ref->error_handler == $new_handler
    ;
    my $routes = 'TestRoutes';
    eval "use $routes";
    skip('Unable to load routes', $tests)
        unless eval { $routes->can('route') }
    ;
    my %request_params = (
        path        => 'some/special/path',
        cgi         => { foo => 'bar' },
        headers     => { REQUEST_METHOD => 'GET' },
        route_handler   => $routes,
    );
    eval {
        $request_params{path_params} = $routes->parse_path( $request_params{path} );
    };
    skip('Problem with route path parsing', $tests) unless $request_params{path_params};
    my $result = eval { $ctl_ref->process_request(%request_params) };
    isa_ok($result, $exception_class) or skip('Error is not the proper object type', $tests - 1);

    is($result->error, "error_action: $ctl_ref object\n", 'process_request() error attribute');

    is(
        ($result->can('route_handler') && $result->route_handler),
        $request_params{route_handler},
        'process_request() route_handler attribute',
    );
    is(
        ($result->can('path') && $result->path),
        $request_params{path},
        'process_request() path attribute',
    );
    is_deeply(
        ($result->can('path_params') && $result->path_params),
        $request_params{path_params},
        'process_request() path_params attribute',
    );
    isa_ok(
        ($result->can('controller') && $result->controller),
        $ctl_ref,
    );
    ok(
        ($result->can('request_class') && $result->request_class),
        'process_request() request_class attribute',
    );
    is_deeply(
        ($result->can('cgi') && $result->cgi),
        $request_params{cgi},
        'process_request() cgi attribute',
    );
    is_deeply(
        ($result->can('headers') && $result->headers),
        $request_params{headers},
        'process_request() headers attribute',
    );
    is(
        ($result->can('action') && $result->action),
        'error_action',
        'process_request() action attribute',
    );

    # exceptions thrown should be from the controller class on which process_request
    # was invoked, not on a controller instance.
    my $alt_handler = sub {
        my $invocant = shift;
        return blessed($invocant) ? blessed($invocant) . ' object' : $invocant;
    };
    eval { $ctl_ref->error_handler( $alt_handler ) };
    skip('Unable to set alternate error handler', 2)
        unless $ctl_ref->error_handler == $alt_handler
    ;
    $result = eval { $ctl_ref->process_request( %request_params, route_handler => 'a bad handler' ) };
    is(
        $result,
        $ctl_ref,
        'process_action() exception on invocant for bad route handler',
    );
    $result = eval { $ctl_ref->process_request( %request_params, path => 'bad' ) };
    is(
        $result,
        $ctl_ref,
        'process_action() exception on invocant for bad controller',
    );
}

eval { $ctl_str->error_handler( '' ) };
#diag($@) if $@;
cmp_ok( $@,  '=~', qr{ControllerErrorHandler}, 'error_handler() disallows the "" method name' );

