package IC::Controller::Test;

use strict;
use warnings;

use Interchange::Deployment;

# We're not conducting tests herein, we just want to be sure Test::More actually exists.
require Test::More;

use IC::Controller;
use IC::Controller::Route::Test;
use Scalar::Util qw/blessed/;
use Exporter;

use base qw/Exporter/;

@IC::Controller::Test::EXPORT = qw/
    controller
    routes
    response
    request
    content
    headers
    status_cmp_ok
    content_cmp_ok
    header_ok
    get_render_calls
    reset_render_calls
/;

=pod

=head1 NAME

IC::Controller::Test -- A module for controller-oriented unit testing

=head1 SYNOPSIS

Controller modules derived from B<IC::Controller> can operate, at least partially,
outside the context of Interchange (depending on their reliance on ITL views).  This
allows us to write unit tests for individual controllers in order to benefit from
test-driven development within application code.  However, the details of representing
and processing a test request with a B<IC::Controller> derivative are non-trivial,
being at best overly tedious to do repeatedly and at worst a signficant barrier to
entry.

B<IC::Controller::Test> provides a basic interface for issuing test requests
to a given controller, relying on B<IC::Controller::Route::Test> for extremely
flexible, generic routing that can itself be used for verification purposes.

=head1 USAGE

B<IC::Controller::Test> makes some assumptions.

=over

=item *

You're only testing one controller at a time

=item *

You're using Test::More as your basic testing tool

=item *

You aren't also trying to test a given route package (B<IC::Controller::Route>)
to verify specific path parsing/generation behavior

=back

As long as you follow the above guidelines, things should work.

In order to test a given controller, you need to tell B<IC::Controller::Test>
about it.  You can do that via the controller package name, or via the controller's
I<registered_name> (see B<IC::Controller> for more).

It is extremely important
that you use/require the controller package in question B<before> using
B<IC::Controller::Test>, or order to be certain that the controller is properly
registered before the testing system and testing routes are initialized.

=head2 EXAMPLE

Let's assume that we have a controller package B<App::Foo>, with I<registered_name>
of 'foo':

 package App::Foo;
 use IC::Controller;
 use base qw/IC::Controller/;
 
 sub speak {
     my $self = shift;
     my $message = $self->parameters->{message} || 'arf! arf!';
     $self->response->headers->status('200 ok');
     $self->response->headers->content_type('text/plain');
     $self->response->buffer( "I say to thee: $message" );
     return;
 }
 
 1;

In this supremely useful controller, we're not bothering with views or anything like
that (though we could use B<Text::ScriptTemplate> views if we wanted; they work fine
outside of IC and are therefore readily testable).  All we're really doing is returning
a text string to the client, the contents thereof determined by the "message" parameter
(which is presumably coming in through the path params, though it could be a GET variable).
If the parameter isn't set, we use an obviously very sensible default.

Let's test this fine application.

 use App::Foo;
 use IC::Controller::Test;
 use Test::More tests => 5;
 
 # Tell IC::Controller::Test that we're using the "foo" controller;
 # this could also be done using the "App::Foo" package name.
 controller('foo');
 
 # Issue a request to get the default response of the speak action
 request( action => 'speak' );
 
 # test assertion: the status code is 200
 status_cmp_ok('=~', qr/^200\b/, 'speak action: status code 200');
 
 # test assertion: the content type headder is text/plain
 header_ok('Content-Type', 'speak action: content-type correct', 'text/plain');
 
 # test assertion: the content meets our expectations
 content_cmp_ok(
     'eq',
     'I say to thee: arf! arf!',
     'speak action: default content',
 );
 
 # Let's issue another request with some parameters
 request( action => 'speak', parameters => { message => 'testing123' } );
 
 content_cmp_ok(
     'eq',
     'I say to thee: testing123',
     'speak action: message parameter',
 );
 
 # For fun, let's verify that only two headers are set.  we'll use
 # a standard Test::More assertion for this, but use the response()
 # function to get at the response object directly.
 cmp_ok(
     scalar(keys( %{response->headers->raw} )),
     '==',
     2,
     'speak action: only two headers set',
 );

That's it.  We still bring in Test::More to control the test.  The
helper test assertions provided by B<IC::Controller::Test> wrap Test::More
assertions, so it's effectively just an extension of Test::More.  It's test
functions can be used as if they were part of Test::More, meaning that they
affect the running stats that Test::More tracks.

=head1 EXPORTED FUNCTIONS

The various subs exported by B<IC::Controller::Test> can be divided into
three different types:

=over

=item *

Configuration routines that affect/determine the state of B<IC::Controller::Test>
and its operations.

=item *

Request/Response routines for issuing test requests and inspecting the results.

=item *

Test assertions in the style of Test::More that are convenience functions for
making assertions about the outcome of a request.

=back

We'll consider each in turn.

=head2 CONFIGURATION FUNCTIONS

=over

=item B<controller( [ $package_or_registered_name ] )>

Gets/sets the controller package against which test requests are issued.  You
must set this in a test script in order for B<IC::Controller::Test> to do anything
meaningful for you.

When called without arguments, I<controller()> returns the controller package name.

when called with an argument, I<controller()> sets the current controller package
to the value provided for I<$package_or_registered_name>.  As that name suggests,
you may provide either a package name (like "App::Foo" in our example) or the
I<registered_name> of the controller you would like to test.  In either case, the
controller specified must have been loaded already; B<IC::Controller::Test> does
not do this for you.

=item B<routes( [ $route_handler ] )>

Gets/sets the route package that is used for request processing and path generation
and/or examination within test requests.  Like I<controller()>, this simply returns
the current setting when invoked without arguments, but will set the current route
package if invoked with an argument.  The I<$route_handler> value provided needs
to support the I<generate_path()> and I<parse_path()> methods, which means it can
be an instance or subclass package name of B<IC::Controller::Route>, or an instance
of B<IC::Controller::Route::Object>.

The default is to use B<IC::Controller::Route::Test>, a specialized routing package
that is designed to support any arbitrarily complex combination of parameters with
any controller and any action.  For general use, it is recommended that you stick
with the default, unless you have a specific need to validate the behavior of your
controller in combination with a particular set of routing rules.

=back

=cut

my $controller;
sub controller {
    if (@_) {
        my $ctl = shift;
        if (defined $ctl and ! UNIVERSAL::can($ctl, 'process_request')) {
            $ctl = eval { blessed(IC::Controller->get_by_name($ctl)) };
            die "Invalid controller specified.  Please provide a package name or registered name. ($@)\n"
                if $@
            ;
        }
        $controller = $ctl;
    }
    return $controller;
}

my $route;
sub routes {
    if (@_) {
        my $rte = shift;
        die "Invalid route package '$rte' specified.\n"
            if defined($rte)
            and !(
                UNIVERSAL::can($rte, 'generate_path')
                and UNIVERSAL::can($rte, 'parse_path')
            )
        ;
        $route = $rte;
    }
    $route ||= 'IC::Controller::Route::Test';
    return $route;
}

=pod

=head2 REQUEST/RESPONSE FUNCTIONS

=over

=item B<request( %options )>

Invokes a request for a given action on the current controller (as returned by
the I<controller()> function, with the parameters hash set to whatever you
provide.

This does not make an actual HTTP request; it invokes I<process_request()> on
the current controller package, going through the general MVC routing/dispatch
process.  It uses the current route handler (I<routes()>) to generate a path
that expresses the controller/action/parameters combination provided in I<%options>,
which should in turn result in an instance of the current controller being created
and the I<action> invoked upon that instance.

If you play with the I<routes()> setting yourself, this behavior may break down,
depending on your route setup.

The return value will be a true/false depending on whether or not the request
invoked successfully generated a response.  Wrapping calls to I<request()> in
an eval { ... } may be helpful, as it invokes a hefty bit of logic within the
framework itself, as well as the logic in the action you're testing.

You can also gain access to the context passed to the render() subroutine through 
the I<get_render_calls()> function.  It will return an array of all the calls to 
render().  You can reset the variable that internally stores all the calls with
I<reset_render_calls()>.

When I<request()> is invoked, it unsets the I<response()> instance.  The response
object generated by the request will be set in I<response()> after the request
process is complete if that request was able to execute without throwing an
(untrapped) exception.

The I<%options> hash may contain a number of different arguments.
The following arguments are specific to I<request()>:

=over

=item I<action> (required)

The action to invoke on the current controller.  If this is not specified,
an exception is thrown.

=item I<method>

The HTTP request method to simulate for the request.  Use this if the action you
wish to test behaves differently in response to GET versus POST, for example.

The standard HTTP request types are accepted: get, put, post, head, delete, options.

If unspecified, this defaults to GET.  Note that it ends up setting the relevant
Interchange request header in the header hash provided to the controller; if you provide
this hash yourself, the I<method> value will overwrite the request method header in
the hash you provide.

=item I<parameters>

The hash of parameters you want for this action.  Defaults to an empty hash if
not specified.  Note that the actual parameters hash seen by the action code will
have more information than the hash you provide; this is because the controller, action,
and request method will likely be present in it as well.

=back

The B<request()> routine passes through all other parameters in I<%options> to the
I<process_request()> method invoked on the current controller.  Therefore, you may
specify things like I<route_handler>, I<headers>, I<cgi>, etc.  See the
B<IC::Controller> docs for more on I<process_request()> arguments.

Note that while I<route_handler> will be honored if it is specified, I<request()>
will set the route handler to be the current route (I<routes()> by default.

=item B<response( [ $response_object ] )>

Gets/sets the current response object.  When invoked as a settor (with an argument),
the new value must be an instance of B<IC::Controller::Response>.

The primary purpose of this function is to access the response object of the most
recently-issued I<request()> call.  However, you are free to set it yourself if the
need should arise.

=item B<content()>

A convenience function that returns the actual "content" of the response object
returned by I<response()>, accessing the response object's I<buffer()> and dereferencing
it (if it is set at all).  Therefore, the result of this will be a scalar, and presumably
a string.

If the response object is unset, or has no buffer set, I<content()> returns undef.

=item B<headers()>

A convenience function that returns the I<headers> property on the response
object returned by I<response()>  If the response object is unset or has no
headers, this returns undef.

=back

=over

=item B<reset_render_calls()>

Resets the render_calls variable to an empty array.  Use this method when you want to start a new test, with new
rendering or new data.

=back

=over

=item B<get_render_calls()>

Returns the value of the render_calls variable as an array.  The render_calls variable will contain all of the 
parameters passed to render()

=back

=cut

my $response;
sub response {
    if (@_) {
        my $rsp = shift;
        die "Invalid response provided.\n"
            unless !defined($rsp)
            or UNIVERSAL::isa($rsp, 'IC::Controller::Response')
        ;
        $response = $rsp;
    }
    return $response;
}

sub content {
    my $rsp = response();
    return (defined($rsp) && defined($rsp->buffer))
        ? ${ $rsp->buffer }
        : undef
    ;
}

sub headers {
    my $rsp = response();
    return defined($rsp) ? $rsp->headers : undef;
}

sub request {
    my (%opt) = @_;
    response(undef);
    my ($action, $method, $controller, $params) = delete @opt{qw/action method controller parameters/ };
    die "You must specify an action to issue a test request.\n"
        unless defined $action and $action =~ /\S/
    ;
    $method = 'get' unless defined($method);
    die "Invalid method '$method' specified.\n"
        if $method !~ /^(?:get|post|put|delete|head|options)$/i
    ;
    
    $opt{headers} ||= {};
    $opt{headers}->{REQUEST_METHOD} = $method;
    $opt{session} ||= {};
    $params ||= {};
    
    $controller ||= controller();
    die "No controller set for request testing.\n"
        if !$controller
    ;

    my $routes = delete $opt{route_handler} || routes();
    die "No routes set for request testing.\n"
        if !$routes
    ;
    
    $opt{route_handler} = $routes;
    
    my $orig = _wrap_controller_subs();
    
    eval {
        $opt{path} = $routes->generate_path(
            %$params,
            method => $opt{headers}->{REQUEST_METHOD},
            action => $action,
            controller => $controller->registered_name,
        );
        response( $controller->process_request(%opt) );
    };
    die "Error preparing/executing request: $@\n" if $@;
    
    _restore_controller_subs( $orig );
    
    return defined(response());
}

# Holds the parameters passed to request
my @render_calls;

sub reset_render_calls {
   # Set render_calls to an empty array
   @render_calls = ();
}

sub get_render_calls {
    return @render_calls;
}

# Called within request to 'remember' the original render subroutine, and override
# with a new one that stores the parameters
sub _wrap_controller_subs {
    my $controller_package = controller();
    my %originals;
    
    # Store the original render subroutine
    $originals{render} = $controller_package->can('render');
       
    # define a new subroutine that also stores the parameters in @render_calls
    my $new_sub = sub {
        my $self = shift;
        push @render_calls, { @_ };
        return $originals{render}($self,@_);
    };
    
    # Redefine the render subroutine
    {
        no strict 'refs';
        no warnings;
        my $name = $controller_package . '::render';
        *$name = $new_sub;
    }
    
    return \%originals;
}

# Restores the render() subroutine to it's original state
sub _restore_controller_subs {
    my $originals = shift;
    for my $key (keys %$originals) {
        my $name = controller() . '::' . $key;
        no strict 'refs';
        no warnings;
        *$name = $$originals{$key};
    }
    return;
}

=head2 TEST ASSERTIONS

The test assertion subs can be used just like the various subs of Test::More.  They
are intended to make it easier to perform common checks against a response.

Each of them operates against the response object returned by I<response()>, meaning
that they check the results of your most recent I<request()>, or a custom response
object that you set yourself if you used I<response()> as a setter.

The test name ($test_name) is always optional.  In cases where the $test_name is
not the last possible argument, you can provide an undef for the $test_name in order
to specify the later arguments.

=over

=item B<content_cmp_ok( $operator, $expected, $test_name )>

Like Test::More's I<cmp_ok>, with the value to be tested being drawn
from the content of the current response (via I<content()>).

=item B<header_ok( $header_name, $test_name, $expected )>

Passes if the header specified by I<$header_name> is Perly-true in the
response object.  If an expected value is provided (via I<$expected>),
passes if the value of the header exactly matches the expected value
(using Test::More's I<is()>).

=item B<redirect_ok()> TO-DO; NOT COMPLETE

This ultimately will be a way of validating the path of a local redirect.

It needs to be completed and tested, which will happen when the need is greater.

=item B<status_cmp_ok( $operator, $expected, $test_name )>

Like I<cmp_ok>, with the value to be tested being drawn from the status line
of the current response headers (via I<headers()->status()).

=back

=cut

sub redirect_ok {
    my %opt = @_;
    my ($params, $exact, $action, $controller,);
}

sub status_cmp_ok {
    # args: operator, value, testname
    my ($op, $expected, $name) = @_;
    return Test::More::cmp_ok(
        (defined(headers()) ? headers()->status() : undef),
        $op,
        $expected,
        $name,
    );
}

sub content_cmp_ok {
    # args: operator, value, testname
    my ($op, $expected, $name) = @_;
    return Test::More::cmp_ok(
        content(),
        $op,
        $expected,
        $name,
    );
}

sub header_ok {
    # args: header name, test name,  optional compare value (equality)
    my $header = shift;
    my $name = shift;
    my @args;
    if (@_) {
        return Test::More::is(
            (defined(headers()) ? headers()->raw->{$header} : undef),
            shift,
            $name,
        );
    }
    else {
        return Test::More::ok(
            ( defined(headers()) && headers()->raw->{$header} ),
            $name,
        );
    }
}

1;

__END__

=pod

=head1 SEE ALSO

=over

=item B<Test::More>

If you want to use this module for testing controllers, you'll need to make use
of Test::More as well.

=item B<IC::Controller>

To better-understand the details of controllers, the I<process_request()> method
that underlies this module's I<request()> function, etc., this is the authoritative
place to start.

=item B<IC::Controller::Route::Test>

The default route handler package that makes for extremely flexible path generation
and parsing, which is critical for testing of controllers in a way that is decoupled
from any particular application route handler.

You shouldn't need to know how to use it, but if you're curious, there you go.

=item B<IC::Controller::Response>

The response object definition; helpful to know if you're going to be making
assertions about the outcome of a request.

=back

=head1 CREDITS

Original author: Ethan Rowe (ethan@endpoint.com)

=cut
