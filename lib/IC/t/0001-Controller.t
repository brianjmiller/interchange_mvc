#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More (tests => 120);
use Interchange::Deployment;

my $class          = 'IC::Controller';
my $response_class = "${class}::Response";
BEGIN: {
	require_ok( $class );
}

my $controller = $class->new;
isa_ok( $controller, $class );

diag('Parameter transforms');
$controller->parameters( {} );
is_deeply(
	$controller->parameters,
	{},
	'parameters() empty hash',
);

$controller->parameters( { foo => 'bar' } );
is_deeply(
	$controller->parameters,
	{ foo => 'bar' },
	'parameters() simple flat variable',
);

$controller->parameters( { 'foo' => "bar\0baz" } );
is_deeply(
	$controller->parameters,
	{ foo => [ qw( bar baz ) ] },
	'parameters() null separated value to array ref (2 elements)',
);

$controller->parameters( { 'foo' => "bar\0bas\0baz" } );
is_deeply(
	$controller->parameters,
	{ foo => [ qw( bar bas baz ) ] },
	'parameters() null separated value to array ref (3 elements)',
);

$controller->parameters( { 'foo[]' => undef } );
is_deeply(
	$controller->parameters,
	{ foo => [] },
	'parameters() name ending in empty brackets to array ref (empty set)',
);

$controller->parameters( { 'foo[]' => 'bar' } );
is_deeply(
	$controller->parameters,
	{ foo => [ 'bar' ] },
	'parameters() name ending in empty brackets to array ref (1 element)',
);

$controller->parameters( { 'foo[a]' => 'bar' } );
is_deeply(
	$controller->parameters,
	{ foo => { a => 'bar' } },
	'parameters() simple hash variable',
);

$controller->parameters( { 'foo[a][b]' => 'bar' } );
is_deeply(
	$controller->parameters,
	{ foo => { a => { b => 'bar', }, }, },
	'parameters() double-nested hash variable',
);

$controller->parameters( { 'foo[a][b][c]' => 'bar' } );
is_deeply(
	$controller->parameters,
	{ foo => { a => { b => { c => 'bar' } } } },
	'parameters() triple-nested hash variable',
);

$controller->parameters( { 'foo[a][b][c]' => 'bar', 'foo[a][blah]' => 'blee', } );
is_deeply(
	$controller->parameters,
	{ foo => { a => { b => { c => 'bar' }, blah => 'blee', } }, },
	'parameters() nesting siblings',
);

$controller->parameters( { foo => 'bar', 'foo[a]' => 'bar', } );
is_deeply(
	$controller->parameters,
	{ foo => { a => 'bar' } },
	'parameters() hash variable wins in collision with flat variable',
);

$controller->parameters( { ah => 'um', 'charles_mingus[instrument]' => 'bass', } );
is_deeply(
	$controller->parameters,
	{ ah => 'um', charles_mingus => { instrument => 'bass', }, },
	'parameters() mix and match',
);

$controller->parameters( { array => join("\0", qw(x y z)), 'hash[array]' => "a\0b\0c", } );
is_deeply(
    $controller->parameters,
    { array => [qw( x y z )], hash => { array => [qw( a b c )], }, },
    'parameters() transforms null-split values into arrayrefs'
);

diag('Parameter preparation (URL and GET/POST data)');
my %headers = (
	REQUEST_METHOD	=> 'GET',
);
my %cgi = (
	cgi_simple => 1,
	'cgi_one[1]' => 1,
	'cgi_two[1][1]' => 1,
);
my %path = (
	path_simple => 1,
	'path_one[1]' => 1,
	'path_two[1][1]' => 1,
);
my %expected = (
	cgi_simple	=> 1,
	cgi_one		=> { 1 => 1, },
	cgi_two		=> { 1 => { 1 => 1, }, },
	path_simple	=> 1,
	path_one	=> { 1 => 1, },
	path_two	=> { 1 => { 1 => 1, }, },
);
my $request_class = $class . '::Request';
$controller->request( $request_class->new( cgi => \%cgi, headers => \%headers, ) );
isa_ok( $controller->request, $request_class );

$controller->prepare_parameters( { %path } );
is_deeply(
	$controller->parameters,
	\%expected,
	'prepare_parameters(): basic merge of GET/POST and path parameters, with associated transforms',
);

$cgi{override} = 'cgi';
$path{override} = 'path';
$expected{override} = 'path';
$controller->prepare_parameters( { %path } );
is_deeply(
	$controller->parameters,
	\%expected,
	'prepare_parameters(): path parameter overrides GET/POST parameter',
);

diag('Registered name verification');
package Bogus::Test::Foo;
use Moose;
extends $class;

__PACKAGE__->registered_name( 'foo' );
has foo => ( is => 'rw', );

1;

package Bogus::Test::Bar;
use Moose;
extends $class;

__PACKAGE__->registered_name( 'bar' );
has bar => ( is => 'rw', );

package main;

cmp_ok(
	Bogus::Test::Foo->registered_name,
	'eq',
	'foo',
	'registered_name: get/set 1',
);

cmp_ok(
	Bogus::Test::Bar->registered_name,
	'eq',
	'bar',
	'registered_name: get/set 2',
);

is_deeply(
	[ $class->controller_names ],
	[qw( bar foo )],
	'controller_names',
);

Bogus::Test::Foo->registered_name('fu');
cmp_ok(
	Bogus::Test::Foo->registered_name,
	'eq',
	'fu',
	'registered_name: reset',
);

Bogus::Test::Foo->registered_name(undef);
ok( ! defined Bogus::Test::Foo->registered_name );
is_deeply(
	[ $class->controller_names ],
	[qw( bar )],
	'controller_names: after clearing...',
);

Bogus::Test::Foo->registered_name('foo');
ok( Bogus::Test::Foo->registered_name eq 'foo' );

my $foo = IC::Controller->get_by_name( 'foo' );
isa_ok(
	$foo,
	'Bogus::Test::Foo',
);

ok( (! defined $foo->foo), 'foo property not defined' );

my $bar = IC::Controller->get_by_name( 'bar' );
isa_ok(
	$bar,
	'Bogus::Test::Bar',
);

$foo = IC::Controller->get_by_name( 'foo', foo => 'blah' );
isa_ok(
	$foo,
	'Bogus::Test::Foo',
);

cmp_ok(
	$foo->foo,
	'eq',
	'blah',
	'get_by_name constructor arguments',
);

diag('url generation');
package Test::TestControllerUrl;
use base qw(IC::Controller);
__PACKAGE__->registered_name('urls');
1;
package Test::TestControllerUrl2;
use base qw(IC::Controller);
__PACKAGE__->registered_name('urls2');
1;
package main;

my $url_base = $Vend::Cfg->{VendURL} = 'http://blah.com/ic/blah';
$Vend::Cfg->{SecureURL} = 'https://blah.com/ic/blah';

$controller = $class->get_by_name( 'urls' );
$controller->route_handler(
    IC::Controller::Route->new
);
$controller->route_handler->route(
    pattern => ':controller',
    action => 'index',
);

my $controller_alt = $class->get_by_name('urls2');
IC::Controller::HelperBase->bind_to_controller();

cmp_ok(
    $controller->url(
        action => 'index',
        route_handler => $controller->route_handler,
        controller => $controller_alt->registered_name,
        no_session => 1,
    ),
    'eq',
    $url_base . '/' . $controller_alt->registered_name,
    'url(): controller name specified used',
);

cmp_ok(
    $controller->url(
        action => 'index',
        no_session => 1,
    ),
    'eq',
    $url_base . '/' . $controller->registered_name,
    'url(): controller falls back to invocant controller',
);

IC::Controller::HelperBase->bind_to_controller( $controller_alt );
$controller_alt->route_handler( $controller->route_handler );

cmp_ok(
    $controller->url(
        action => 'index',
        no_session => 1,
    ),
    'eq',
    $url_base . '/' . $controller_alt->registered_name,
    'url(): defaults to bound controller when available',
);

diag('redirection');
IC::Controller::HelperBase->bind_to_controller( $controller );
$controller->response( $response_class->new );
$controller->content_type( undef );
$controller->redirect(
    action => 'index',
    no_session => 1,
);
cmp_ok(
    $controller->response->headers->location,
    'eq',
    $url_base . '/' . $controller->registered_name,
    'redirect(): location header',
);
cmp_ok(
    $controller->response->headers->status,
    'eq',
    '301 moved',
    'redirect(): default status header',
);
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    $controller->default_content_type,
    'redirect(): default content type',
);

$controller->response( $response_class->new );
$controller->content_type( 'text/plain' );
$controller->redirect(
    action => 'index',
    no_session => 1,
);
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    $controller->content_type,
    'redirect(): controller-specified content type',
);

$controller->response( $response_class->new );
$controller->content_type( undef );
$controller->response->headers->content_type( 'text/html; encoding="utf-8"' );
$controller->redirect(
    action => 'index',
    no_session => 1,
);
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    'text/html; encoding="utf-8"',
    'redirect(): response content_type header preserved',
);

$controller->response( $response_class->new );
$controller->redirect(
    action => 'index',
    no_session => 1,
    status => '302 moved',
);
cmp_ok(
    $controller->response->headers->status,
    'eq',
    '302 moved',
    'redirect(): status header specified in parameters',
);

diag('render testing');
package Test::TestController;
use Moose;
extends qw(IC::Controller);
__PACKAGE__->registered_name( 'test' );
has test => ( is => 'rw', );
has verify => ( is => 'rw', isa => 'ArrayRef', );
1;

package main;
my $view_path = __FILE__;
$view_path =~ s/\.t$//;
$controller = $class->get_by_name( 'test', view_path => $view_path );

is(
    $controller->logger,
    IC::Log->logger,
    'logger() default behavior',
);

$controller->set_logger( IC::Log::Interchange->new( quiet_fallback => 1 ) );
is(
    $controller->logger,
    $controller->get_logger || 'buggy attribute reader',
    'logger() instance override behavior',
);

$controller->request( $request_class->new(
	cgi => {},
	headers => {
		REQUEST_METHOD => 'GET',
	},	
) );
$controller->prepare_parameters( { controller => 'test', action => 'verify', } );
$controller->test( 'something' );
$controller->verify( [qw( one two three )] );
my $content = $controller->render_local(
	view	=> 'test/verify.tst',
	context	=> {
		verify	=> $controller->verify,
	},
);

my $simple_regex = qr{^verify: one two three\s*$};
cmp_ok(
	$content,
	'=~',
	$simple_regex,
	'render_local() basic view with marshalling',
);

$controller->verify([qw( four five six )]);
$content = $controller->render_local(
	view	=> 'test/verify.tst',
	context	=> {
		verify	=> $controller->verify,
	},
	layout	=> 'layouts/test.tst',
);

my $full_regex = qr{^method: get\s+test: something\s+action: verify: four five six\s*$}m;
cmp_ok(
	$content,
	'=~',
	$full_regex,
	'render_local() view and layout with proper marshalling',
);

$controller->view_default_extension( 'tst' );
$controller->render( context => { verify => $controller->verify } );
cmp_ok(
	${ $controller->response->buffer },
	'=~',
	$full_regex,
	'render() view and layout defaults',
);

eval {
	$controller->render( context => { verify => $controller->verify } );
};
ok( $@, 'render() throws exception on second attempt', );

$controller->response->buffer( undef );
$controller->verify([qw( one two three )]);
$controller->render( context => { verify => $controller->verify }, layout => undef, );
cmp_ok(
	${ $controller->response->buffer },
	'=~',
	$simple_regex,
	'render() view with layout deactivated',
);

$controller->response->buffer( undef );
$controller->render(
	view	=> 'layouts/test.tst',
	layout	=> undef,
	context	=> {
		test			=> 't',
		action_content	=> 'a',
		request			=> $controller->request,
	},
);
cmp_ok(
	${ $controller->response->buffer },
	'=~',
	qr{^method: get\s+test: t\s+action: a\s*$}m,
	'render() override default view, layout deactivated',
);

# verify the status and content type header behaviors
$controller->response( $response_class->new );
$controller->content_type( undef );
cmp_ok(
    $controller->default_content_type,
    'eq',
    'text/html',
    'default_content_type() value'
);

my %render_params = ( layouts => undef, context => { verify => $controller->verify }, );
$controller->render( %render_params, );
cmp_ok(
    $controller->response->headers->status,
    'eq',
    '200 OK',
    'render() headers status default',
);
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    $controller->default_content_type,
    'render() headers content_type default',
);

$controller->response( $response_class->new );
$controller->content_type('text/html; charset="utf8"');
$controller->response->headers->status( '301 moved' );
$controller->render( %render_params, );
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    $controller->content_type,
    'render() headers content_type from controller attribute',
);
cmp_ok(
    $controller->response->headers->status,
    'eq',
    '301 moved',
    'render() headers status preserved when already set',
);

$controller->response( $response_class->new );
$controller->response->headers->content_type('text/plain');
$controller->render( %render_params, );
cmp_ok(
    $controller->response->headers->content_type,
    'eq',
    'text/plain',
    'render() headers content_type preserved when already set',
);

# check that the foo controller lack of layout doesn't throw an error by default.  '
$foo->request( $controller->request );
$foo->view_path( $controller->view_path );
$foo->prepare_parameters( { controller => $foo->registered_name, action => 'verify' } );
$foo->view_default_extension( 'tst' );
$foo->render(
	view	=> 'test/verify',
	context => {
		verify	=> [qw(one two three)],
	},
);
cmp_ok(
	${ $foo->response->buffer },
	'=~',
	$simple_regex,
	'render() default layout missing simply renders view',
);

$foo->response->buffer( undef );
eval {
	$foo->render(
		layout => 'layouts/' . $foo->registered_name,
	);
};
ok( $@, 'render() with default layout explicitly stated throws error when missing', );

diag('process_request() testing');
my (
	$route_class,
	$route_object,
	$controller_class,
);

# We'll use this for cache testing later, so don't mind the caching-oriented things
package Bogus::Test::Controller;
use Moose;
extends qw(IC::Controller);
$controller_class = __PACKAGE__;
$controller_class->registered_name('full_test');
has full_test => ( is => 'rw', );
{
    my $run_count = 0;
    sub reset_count { $run_count = 0 }
    sub run_count { return $run_count }
    sub cache_me {
        my $self = shift;
        $self->response->buffer( 'Running for count: ' . ++$run_count );
        $self->response->headers->status( '200 OK' );
        return;
    }
}
sub no_cache {
    my $self = shift;
    return $self->cache_me(@_);
}
sub action {
	my $self = shift;
	my %params;
	$params{view} = $self->parameters->{view}
		if defined $self->parameters->{view}
	;
	$params{context} = {
		my_view	=> $self->parameters->{view},
		my_arg	=> $self->parameters->{arg},
		cgi_hash	=> $self->parameters->{cgi_hash},
		url_hash	=> $self->parameters->{url_hash},
	};
	$self->full_test( $self->parameters->{arg} );
	$self->render(
		%params,
	);
	return;
}
sub urls {
    my $self = shift;
    $self->render(
        layout => undef,
        context => {
            url => $self->url(
                action => $self->parameters->{action},
                parameters => {
                    arg => $self->parameters->{arg},
                    view => $self->parameters->{view},
                },
                no_session => 1,
            ),
        },
    );
    return;
}
sub redirects {
    my $self = shift;
    $self->redirect(
        action => $self->parameters->{action},
        parameters => {
            arg => $self->parameters->{arg},
            view => $self->parameters->{view},
        },
        no_session => 1,
    );
    return;
}
sub view_urls {
    my $self = shift;
    $self->render(
        layout => undef,
        context => {
            controller => $self->registered_name,
            action => $self->parameters->{action},
            arg => $self->parameters->{arg},
            view => $self->parameters->{view},
        },
    );
    return;
}
sub view_render {
    my $self = shift;
    $self->render(
        layout => undef,
        context => {
            arg => $self->parameters->{arg},
        },
    );
    return;
}
{
    my $calls = 0;
    sub process_initialization {
        $calls++;
        return;
    }
    sub initialization_count {
        return $calls;
    }
}
1;

package Bogus::Test::Route;
use base qw(IC::Controller::Route);
$route_class = __PACKAGE__;
# build the route object first, then build the
# special route class from it...
$route_object = IC::Controller::Route->new;
$route_object->route(
	pattern     => 'no_controller',
	controller	=> 'does_not_exist',
	action		=> 'foo',
);
$route_object->route(
	pattern     => ':controller/:action/:arg/:view',
	defaults    => {
		controller	=> $controller_class->registered_name,
		action	=> 'action',
		arg		=> 'default',
		view	=> undef,
		'url_hash[x]' => 'x',
		'url_hash[y]' => 'y',
	},
);
$route_class->add_route( $_ )
	for @{ $route_object->routes }
;
1;

package Bogus::Test::Request;
use base qw(IC::Controller::Request);
$request_class = __PACKAGE__;
1;

package main;

# set up the stinkin' IC globals for URLs...    '
$Vend::Cfg->{VendURL} = 'http://foo.com/ic/foo';
$Vend::Cfg->{SecureURL} = 'https://foo.com/ic/foo';

# do the same set of tests against route class
# versus route object
for my $router ($route_class, $route_object) {
	SKIP: {
		my $name = $controller_class->registered_name;
		my $default_path = $router->generate_path(
			controller	=> $name,
			action		=> 'action',
			arg			=> 'default',
		);
		my $specific_path = $router->generate_path(
			controller	=> $name,
			action		=> 'action',
			arg			=> 'arg',
			view		=> 'full_test',
		);
		my $bad_path = $router->generate_path(
			controller	=> 'does_not_exist',
			action		=> 'foo',
		);
        my $url_path = $router->generate_path(
            controller  => $name,
            action      => 'urls',
            arg         => 'foo',
        );
        my $redirect_path = $router->generate_path(
            controller  => $name,
            action      => 'redirects',
            arg         => 'foo',
        );
        my $view_url_path = $router->generate_path(
            controller  => $name,
            action      => 'view_urls',
            arg         => 'blah',
        );
        my $view_render_path = $router->generate_path(
            controller  => $name,
            action      => 'view_render',
            arg         => 'render test',
        );
		skip(
			5,
			sprintf(
				'Could not generate five necessary paths (paths received: "%s", "%s", "%s", "%s", "%s", "%s")',
				map {
					defined($_) ? $_ : '-- undef --'
				} (
					$default_path,
					$specific_path,
					$bad_path,
                    $url_path,
                    $redirect_path,
                    $view_url_path,
				),
			),
		) unless defined $default_path
			and defined $specific_path
			and defined $bad_path
            and defined $url_path
            and defined $redirect_path
            and defined $view_url_path
		;

		my %full_params = (
			view_path	=> $view_path,
			view_default_extension	=> 'tst',
			cgi		=> {
				'cgi_hash[a]' => 'a',
				'cgi_hash[b]' => 'b',
			},
			headers	=> {
				REQUEST_METHOD	=> 'GET',
			},
			route_handler	=> $router,
		);
		# coerce to a string, then escape parens
		my $route_pattern = '' . $router;
		$route_pattern =~ s/([()])/\\$1/g;
		# Tests to run:
		# 1. bad path throws error (no controller)
		# 2. default path with default request class
		# 3. default path with specified request class
		# 4. specific path with default request class
		# 5. specific path with specified request class
        # 6. url path with link generation
        # 7. redirect path with link generation
        # 8. nested render with view
		my $test_suffix
			= 'route handler is '
				. (ref($router)
					? 'an object'
					: 'a package name'
				  )
		;
		my $full_result;
		$full_params{path} = $bad_path;
		eval {
			$full_result = $class->process_request(
				%full_params,
			);
		};
		# TO-DO: revise this to be more specific once
		# we have exception classes set up.
		ok(
			$@,
			'process_request(): nonexistent controller throws exception; ' . $test_suffix,
		);

		my $action_pattern = qr{my_arg: default\nmy_view:\s+cgi_hash: a a b b\nurl_hash: x x y y};
		$full_params{path} = $default_path;
		delete $full_params{request_class};
        my $counts = $controller_class->initialization_count;
		$full_result = $class->process_request(
			%full_params,
		);
		cmp_ok(
			${ $full_result->buffer },
			'=~',
			qr(^action: action\ncontroller: $name\nrequest: ${class}::Request\nroute_handler: $route_pattern\n$action_pattern\s*$),
			'process_request(): defaults; ' . $test_suffix,
		);
        cmp_ok(
            $controller_class->initialization_count,
            '==',
            $counts,
            'process_initialization(): not invoked from base class process_request();' . $test_suffix,
        );
        my $prev_buffer = ${ $full_result->buffer };
        $full_result = $controller_class->process_request(
            %full_params,
        );
        cmp_ok(
            ${ $full_result->buffer },
            'eq',
            $prev_buffer,
            'process_request(): result consistent when invoked against subclass rather than base class; ' . $test_suffix,
        );
        cmp_ok(
            $controller_class->initialization_count,
            '==',
            $counts + 1,
            'process_initialization() properly invoked from subclass process_request(); ' . $test_suffix,
        );
		$full_params{request_class} = $request_class;
		$full_result = $class->process_request( %full_params );
		cmp_ok(
			${ $full_result->buffer },
			'=~',
			qr(^action: action\ncontroller: $name\nrequest: $request_class\nroute_handler: $route_pattern\n$action_pattern\s*$),
			'process_request(): defaults with specified request type; ' . $test_suffix,
		);

		delete $full_params{request_class};
		$full_params{path} = $specific_path;
		$action_pattern = qr{my_arg: arg\nmy_view: full_test\ncgi_hash: a a b b\nurl_hash: x x y y};
		$full_result = $class->process_request( %full_params );
		cmp_ok(
			${ $full_result->buffer },
			'=~',
			qr(^action: action\ncontroller: $name\nrequest: ${class}::Request\nroute_handler: $route_pattern\n$action_pattern\s*$),
			'process_request(): specific path with default request type; ' . $test_suffix,
		);

		$full_params{request_class} = $request_class;
		$full_result = $class->process_request( %full_params );
		cmp_ok(
			${ $full_result->buffer },
			'=~',
			qr(^action: action\ncontroller: $name\nrequest: $request_class\nroute_handler: $route_pattern\n$action_pattern\s*$),
			'process_request(): specific path with specified request type; ' . $test_suffix,
		);

        delete $full_params{request_class};
        $full_params{path} = $url_path;
        $full_result = $class->process_request( %full_params );
        chomp ${ $full_result->buffer };
        cmp_ok(
            ${ $full_result->buffer },
            'eq',
            $Vend::Cfg->{VendURL} . '/' . $url_path,
            'process_request(): url path with url generation; ' . $test_suffix,
        );

        $full_params{path} = $redirect_path;
        $full_result = $class->process_request( %full_params );
        cmp_ok(
            $full_result->headers->status,
            'eq',
            '301 moved',
            'process_request(): redirect path gives 301 header; ' . $test_suffix,
        );
        cmp_ok(
            $full_result->headers->location,
            'eq',
            $Vend::Cfg->{VendURL} . '/' . $redirect_path,
            'process_request(): redirect path location header; ' . $test_suffix,
        );

        $full_params{path} = $view_url_path;
        delete $full_params{request_class};
        $full_result = $class->process_request( %full_params );
        chomp ${ $full_result->buffer };
        cmp_ok(
            ${ $full_result->buffer },
            'eq',
            $Vend::Cfg->{VendURL} . '/' . $view_url_path,
            'process_request(): url() helper method with default request type; ' . $test_suffix,
        );

        $full_params{request_class} = $request_class;
        $full_result = $class->process_request( %full_params );
        chomp ${ $full_result->buffer };
        cmp_ok(
            ${ $full_result->buffer },
            'eq',
            $Vend::Cfg->{VendURL} . '/' . $view_url_path,
            'process_request(): url() helper method with specified request type; ' . $test_suffix,
        );

        delete $full_params{request_class};
        $full_params{path} = $view_render_path;
        $full_result = $class->process_request( %full_params );
        chomp ${ $full_result->buffer };
        cmp_ok(
            ${ $full_result->buffer },
            '=~',
            qr{^outer:\s+inner:\s+render\stest\s*$},
            'process_request(): render() helper method; ' . $test_suffix,
        );
	}
}

diag('page caching tests');
# Page cache testing.
# 1.  get/set hashref on cache_pages attr
# 2.  type coercion check from arrayref to hashref on cache_pages attr
# 3.  caches_page() valid
# 4.  caches_page() invalid
# 5.  caches_page() nonexistent action throws exception
# 6.  _determine_cache_handler() returns undef if none available
# 7.  _determine_cache_handler() returns module default if not set on object
# 8.  _determine_cache_handler() returns object's value if set   '
# 9.  _cache_handler_function() uses default handler, as invocant when it has function
# 10. _cache_handler_function() uses default handler, 'IC::Controller::PageCache' when no function
# 11. _cache_handler_function() uses object handler, as invocant when function...
# 12. _cache_handler_function() uses object handler, 'IC::Controller::PageCache' when no function
# 13. set_page_cache() undef if not 'get' request
# 14. set_page_cache() undef if not defined response->buffer
# 15. set_page_cache() undef if not 200 OK
# 16. set_page_cache() undef if no route for requested params
# 17. set_page_cache() sets cache, default handler, handler as invocant
# 18. get_page_cache() gets cache, default handler, handler as invocant
# 19. set_page_cache() sets cache, default handler, package as invocant
# 20. get_page_cache() gets cache, default handler, package as invocant
# 21. set_page_cache() sets cache, object handler, object as invocant
# 22. get_page_cache() gets cache, object handler, object as invocant
# 23. set_page_cache() sets cache, object handler, package as invocant
# 24. get_page_cache() gets cache, object handlers, package as invocant
# 25. get_page_cache() undef if not 'get' request
# 26. get_page_cache() undef if cache doesn't exist   '
# 27. get_page_cache() undef if no route for requested params
# 28. process_request(): no cache set if non-cache action
# 29. process_request(): cache set if cache action (canonical URL)
# 30. process_request(): subsequent cache use if cache action
# 31. process_request(): subsequent cache use from non-canonical URL on cache action
# 32. process_request(): cache set on cache action (non-canonical URL)
# 33. process_request(): subsequent cache use from canonical URL on cache action
# 34. page_cache_no_reads(): default is false
# 35. page_cache_no_reads(): set to true
# 36. page_cache_no_reads()/process_request(): no cache use if page_cache_no_reads()
# 37. page_cache_no_reads()/process_request(): cache use resumes if ! page_cache_no_reads()
package Bogus::Test::PageCache::Simple;
{
    my (%cache, $get, $set, $last_package, $wrapper_package);
    sub set {
        my ($package, %opt) = @_;
        my $i;
        $last_package = $package;
        __PACKAGE__->determine_wrapper_class;
        $set++;
        return ${ $cache{$package} ||= {} }{$opt{key}} = $opt{data};
    }
    sub get {
        my ($package, %opt) = @_;
        $last_package = $package;
        __PACKAGE__->determine_wrapper_class;
        $get++;
        return ${ $cache{$package} || {} }{$opt{key}};
    }
    sub _no_op { $last_package = shift; __PACKAGE__->determine_wrapper_class; return }
    sub clear { return %cache = () };
    sub reset { return $get = $set = $last_package = $wrapper_package = undef; }
    sub last_package { return $last_package; }
    sub wrapper_package { return $wrapper_package; }
    sub set_value { return $set; }
    sub get_value { return $get; }
    sub determine_wrapper_class {
        my $i = 0;
        my ($package, $file, $line, $sub);
        while (($package, $file, $line, $sub) = caller($i) and $package ne 'IC::Controller') { $i++ }
        ($wrapper_package) = $sub =~ /^(.+?)\::[^:]+$/;
    }
}
package Bogus::Test::PageCache::Full;
use base qw(IC::Controller::PageCache Bogus::Test::PageCache::Simple);
sub no_op { return __PACKAGE__->_no_op }
# override so this package/sub will get into the call stack and be visible to tests
sub get_cache {
    my $self = shift;
    return $self->SUPER::get_cache( @_ );
}
sub set_cache {
    my $self = shift;
    return $self->SUPER::set_cache( @_ );
}

package main;
sub IC::Controller::PageCache::no_op { return Bogus::Test::PageCache::Simple::_no_op( 'IC::Controller::PageCache' ) }

$controller_class = 'Bogus::Test::Controller';
my $page_cache_class_simple = 'Bogus::Test::PageCache::Simple';
my $page_cache_class_full = 'Bogus::Test::PageCache::Full';
$route_class = 'Bogus::Test::Route';

$controller_class->cache_pages( { cache_me => 1 } );
is_deeply( $controller_class->cache_pages(), { cache_me => 1 }, 'get/set cache_pages() hashref' );
$controller_class->cache_pages([ qw( cache_me ) ]);
is_deeply( $controller_class->cache_pages(), { cache_me => 1 }, 'cache_pages() coercion from arrayref' );
ok( $controller_class->caches_page( 'cache_me' ), 'caches_page() specified action' );
ok( ! $controller_class->caches_page( 'action' ), 'caches_page() unspecified action' );
eval { $controller_class->caches_page( 'this_does_not_exist' ) };
ok( $@, 'caches_page() nonexistant action throws exception' );

my $cache_controller = $controller_class->new;
ok(
    !defined( $cache_controller->_determine_page_cache_handler ),
    '_determine_page_cache_handler() undef if not specified in class or instance',
);
$controller_class->default_page_cache_handler( $page_cache_class_simple );
is(
    $cache_controller->_determine_page_cache_handler,
    $page_cache_class_simple,
    '_determine_page_cache_handler() class value when instance value unset',
);
$cache_controller->page_cache_handler( $page_cache_class_full );
is(
    $cache_controller->_determine_page_cache_handler,
    $page_cache_class_full,
    '_determine_page_cache_handler() instance value when set',
);

# 9.  _cache_handler_function() uses default handler, as invocant when it has function
$controller_class->default_page_cache_handler( $page_cache_class_full );
$cache_controller = $controller_class->new( route_handler => $route_class );
$page_cache_class_simple->clear;
$page_cache_class_simple->reset;
$cache_controller->_page_cache_handler_function( 'no_op' )->( {} );
is(
    $page_cache_class_simple->last_package,
    $page_cache_class_full,
    '_page_cache_handler_function() default handler, handler as invocant',
);

# 10. _cache_handler_function() uses default handler, 'IC::Controller::PageCache' when no function
$controller_class->default_page_cache_handler( $page_cache_class_simple );
$page_cache_class_simple->reset;
$cache_controller->_page_cache_handler_function( 'no_op' )->( {} );
is(
    $page_cache_class_simple->last_package,
    'IC::Controller::PageCache',
    '_page_cache_handler_function() default handler, handler as argument',
);

# 11. _cache_handler_function() uses object handler, as invocant when function...
$cache_controller->page_cache_handler( $page_cache_class_full );
$page_cache_class_simple->reset;
$cache_controller->_page_cache_handler_function( 'no_op' )->( {} );
is(
    $page_cache_class_simple->last_package,
    $page_cache_class_full,
    '_page_cache_handler_function() instance handler, handler as invocant',
);

# 12. _cache_handler_function() uses object handler, 'IC::Controller::PageCache' when no function
$cache_controller->page_cache_handler( $page_cache_class_simple );
$controller_class->default_page_cache_handler( $page_cache_class_full );
$page_cache_class_simple->reset;
$cache_controller->_page_cache_handler_function( 'no_op' )->();
is(
    $page_cache_class_simple->last_package,
    'IC::Controller::PageCache',
    '_page_cache_handler_function() instance handler, handler as argument',
);

# 13. set_page_cache() undef if not 'get' request
$request_class = $class . '::Request';
my $path_params = {
    controller => $cache_controller->registered_name,
    action => 'cache_me',
};
$cache_controller = $controller_class->new(
    request => $request_class->new( cgi => {}, headers => { REQUEST_METHOD => 'post' } ),
);
$cache_controller->response->buffer( 'foo' );
$cache_controller->response->headers->status( '200 OK' );
ok(
    !defined( $cache_controller->set_page_cache( $path_params )),
    'set_page_cache() undef if not GET request',
);

# 14. set_page_cache() undef if not defined response->buffer
$cache_controller->request->headers( { REQUEST_METHOD => 'get' } );
$cache_controller->response->buffer( undef );
ok(
    !defined( $cache_controller->set_page_cache( $path_params )),
    'set_page_cache() undef if buffer unset',
);

# 15. set_page_cache() undef if not 200 OK
$cache_controller->response->buffer( 'foo' );
$cache_controller->response->headers->status( '404' );
ok(
    !defined( $cache_controller->set_page_cache( $path_params ) ),
    'set_page_cache() undef if status not 200 OK',
);

# 16. set_page_cache() undef if no route for requested params.
$cache_controller->response->headers->status( '200 ok' );
ok(
    !defined( $cache_controller->set_page_cache({ fahrfeghnuegen => 'driving pleasure' }) ),
    'set_page_cache() undef if no route for requested params',
);

# Do these in a loop given their similarities
# 17. set_page_cache() sets cache, default handler, handler as invocant
# 18. check_page_cache() gets cache, default handler, handler as invocant
# 19. set_page_cache() sets cache, default handler, package as invocant
# 20. check_page_cache() gets cache, default handler, package as invocant
# 21. set_page_cache() sets cache, object handler, object as invocant
# 22. check_page_cache() gets cache, object handler, object as invocant
# 23. set_page_cache() sets cache, object handler, package as invocant
# 24. check_page_cache() gets cache, object handlers, package as invocant

my %common_conf = (
    request         => $request_class->new( headers => { REQUEST_METHOD => 'get' } ),
    route_handler   => $route_class,
);
my $common_params = {
    action  => 'cache_me',
    arg     => 'default',
};
$page_cache_class_simple->reset;
$page_cache_class_simple->clear;

for my $conf (
        {
            default_handler     => $page_cache_class_full,
            expected_package    => $page_cache_class_full,
            name                => 'default cache handler, handler is method invocant',
        },
        {
            default_handler     => $page_cache_class_simple,
            name                => 'default cache handler, handler is method argument',
        },
        {
            default_handler     => $page_cache_class_simple,
            object_handler      => $page_cache_class_full,
            expected_package    => $page_cache_class_full,
            name                => 'explicit cache handler, handler is method invocant',
        },
        {
            default_handler     => $page_cache_class_full,
            object_handler      => $page_cache_class_simple,
            name                => 'explicit cache handler,handler is method argument',
        },
    ) {
    $conf->{expected_package} ||= $class . '::PageCache';
    $controller_class->default_page_cache_handler( $conf->{default_handler} );
    $cache_controller = $controller_class->new( %common_conf );
    IC::Controller::HelperBase->bind_to_controller( $cache_controller );
    if (defined $conf->{object_handler}) {
        $cache_controller->page_cache_handler( $conf->{object_handler} );
    }
    $cache_controller->response->buffer( $conf->{name} );
    $cache_controller->response->headers->status( '200 ok' );
    eval { $cache_controller->set_page_cache( $common_params ) };
    diag($@) if $@;
    is_deeply(
        [ $page_cache_class_simple->wrapper_package, $page_cache_class_simple->set_value, ],
        [ $conf->{expected_package}, 1 ],
        "set_page_cache() $conf->{name}",
    );
    $page_cache_class_simple->reset;
    $cache_controller->response( IC::Controller::Response->new );
    eval { $cache_controller->check_page_cache( $common_params ) };
    diag($@) if $@;
    is_deeply(
        [
            $page_cache_class_simple->wrapper_package,
            $page_cache_class_simple->get_value,
            ${$cache_controller->response->buffer || \''},
            lc($cache_controller->response->headers->status),
        ],
        [
            $conf->{expected_package},
            1,
            $conf->{name},
            '200 ok',
        ],
        "check_page_cache() $conf->{name}",
    );
    $page_cache_class_simple->reset;
    $page_cache_class_simple->clear;
}

# 25. get_page_cache() undef if not 'get' request
# 26. get_page_cache() undef if cache doesn't exist   '
# 27. get_page_cache() undef if no route for requested params

# we will rely on the state of the object, store a cache for validity
$cache_controller->response->buffer( 'some test data' );
$cache_controller->response->headers->status( '200 ok' );
eval { $cache_controller->set_page_cache( $common_params ) };
$cache_controller->request->headers({ REQUEST_METHOD => 'post' });
ok(
    !defined(eval { $cache_controller->check_page_cache($common_params) }) && ! $page_cache_class_simple->get_value,
    'check_page_cache() undef if not "get" request',
);
$cache_controller->request->headers({ REQUEST_METHOD => 'get' });
$page_cache_class_simple->clear;
$page_cache_class_simple->reset;
ok(
    !defined(eval { $cache_controller->check_page_cache($common_params) }) && $page_cache_class_simple->get_value,
    'check_page_cache() undef if cache unset',
);
$page_cache_class_simple->reset;
$cache_controller->set_page_cache( $common_params );
$cache_controller->route_handler( IC::Controller::Route->new );
ok(
    !defined(eval { $cache_controller->check_page_cache($common_params) }) && ! $page_cache_class_simple->get_value,
    'check_page_cache() undef if no route for requested params',
);

# 28. process_request(): no cache set if non-cache action
# 29. process_request(): cache set if cache action (canonical URL)
# 30. process_request(): subsequent cache use if cache action
# 31. process_request(): subsequent cache use from non-canonical URL on cache action
# 32. process_request(): cache set on cache action (non-canonical URL)
# 33. process_request(): subsequent cache use from canonical URL on cache action
$page_cache_class_simple->reset;
$page_cache_class_simple->clear;
$controller_class->default_page_cache_handler( $page_cache_class_simple );
$controller_class->cache_pages([qw( cache_me )]);
my %common_params = (
    headers         => { REQUEST_METHOD => 'get' },
    route_handler   => $route_class,
    path            => $controller_class->registered_name . '/cache_me',
);
$controller_class->reset_count;
$controller_class->process_request( %common_params, path => $controller_class->registered_name . '/no_cache', );
# validate that the sub ran, that get/set were not called (because not a caching action)
ok(
    $controller_class->run_count && !( $page_cache_class_simple->get_value || $page_cache_class_simple->set_value ),
    'process_request() no cache get/set if non-cache action',
);

$controller_class->reset_count;
$page_cache_class_simple->reset;
$page_cache_class_simple->clear;
my $response = eval { $controller_class->process_request( %common_params ) };
diag($@) if $@;
my @checks = (
    $controller_class->run_count,
    $page_cache_class_simple->get_value || 0,
    $page_cache_class_simple->set_value || 0,
);
my $expected_content = $response && $response->buffer && ${ $response->buffer };
is_deeply(
    \@checks,
    [ 1, 1, 1, ],
    'process_request() cache set (canonical URL)',
);

$controller_class->reset_count;
$page_cache_class_simple->reset;
$response = eval { $controller_class->process_request( %common_params ) };
diag($@) if $@;
@checks = (
    $controller_class->run_count,
    $page_cache_class_simple->get_value || 0,
    $page_cache_class_simple->set_value || 0,
    $response && $response->buffer && ${$response->buffer},
    $response && $response->headers && lc($response->headers->status),
);
is_deeply(
    \@checks,
    [ 0, 1, 0, $expected_content, '200 ok' ],
    'process_request() subsequent cache use (canonical URL)',
);
$controller_class->reset_count;
$page_cache_class_simple->reset;
$response = eval {
    $controller_class->process_request(
        %common_params,
        path => $controller_class->registered_name . '/cache_me/default'
    )
};
diag($@) if $@;
is_deeply(
    [
        $controller_class->run_count,
        $page_cache_class_simple->get_value || 0,
        $page_cache_class_simple->set_value || 0,
        $response && $response->buffer && ${$response->buffer},
        $response && $response->headers && lc($response->headers->status),
    ],
    [ 0, 1, 0, $expected_content, '200 ok' ],
    'process_request() subsequent cache use (non-canonical URL)',
);

$page_cache_class_simple->clear;
$page_cache_class_simple->reset;
$controller_class->reset_count;
$response = eval {
    $controller_class->process_request(
        %common_params,
        path => $controller_class->registered_name . '/cache_me/default'
    )
};
diag($@) if $@;
$expected_content = $response && $response->buffer && ${$response->buffer};
is_deeply(
    [
        $controller_class->run_count,
        $page_cache_class_simple->get_value || 0,
        $page_cache_class_simple->set_value || 0,
    ],
    [ 1, 1, 1 ],
    'process_request() cache set (non-canonical URL)',
);

$controller_class->reset_count;
$page_cache_class_simple->reset;
$response = eval { $controller_class->process_request( %common_params ) };
diag($@) if $@;
is_deeply(
    [
        $controller_class->run_count,
        $page_cache_class_simple->get_value || 0,
        $page_cache_class_simple->set_value || 0,
        $response && $response->buffer && ${ $response->buffer },
        $response && $response->headers && lc($response->headers->status)
    ],
    [ 0, 1, 0, $expected_content, '200 ok', ],
    'process_request() subsequent cache use (canonical URL)',
);

# 34. page_cache_no_reads(): default is false
# 35. page_cache_no_reads(): set to true
# 36. page_cache_no_reads()/process_request(): no cache use if page_cache_no_reads()
# 37. page_cache_no_reads()/process_request(): cache use resumes if ! page_cache_no_reads()

ok(
    ! $controller_class->page_cache_no_reads(),
    'page_cache_no_reads: default is false',
);

$controller_class->page_cache_no_reads(1);
ok(
    $controller_class->page_cache_no_reads,
    'page_cache_no_reads: true value set',
);

$controller_class->reset_count;
$page_cache_class_simple->reset;
$response = eval { $controller_class->process_request( %common_params ) };
diag($@) if $@;
cmp_ok(
    $controller_class->run_count,
    '>',
    0,
    'page_cache_no_reads/process_request(): no cache use if page_cache_no_reads on',
);

$controller_class->page_cache_no_reads(0);
$controller_class->reset_count;
$page_cache_class_simple->reset;
$response = eval { $controller_class->process_request( %common_params ) };
diag($@) if $@;
cmp_ok(
    $controller_class->run_count,
    '==',
    0,
    'page_cache_no_reads/process_request(): cache use resumes if ! page_cache_no_reads',
);

1;
