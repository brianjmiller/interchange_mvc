#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 14);

my $class = 'IC::Controller::Request';
BEGIN: {
	require_ok( $class );
}

my %env = (
	HTTP_COOKIE
		=> 'DL_dn_seen=1; node_id=2222; MV_SESSION_ID=bWyYkfgu:76.19.215.210',
	HTTPS			=> undef,
	REQUEST_METHOD	=> 'GET',
);

my %cgi = (
	mv_session_id	=> 'foo',
	mv_nextpage		=> 'test',
);

my $request = IC::Controller::Request->new( headers => \%env, cgi => \%cgi, );
isa_ok(
	$request,
	$class,
);

# These cookies were taken from a live session from www.crotchet.co.uk
is_deeply(
	[ $request->cookies ],
	[
		{ name => 'DL_dn_seen', value => '1', },
		{ name => 'node_id', value => 2222,},
		{ name => 'MV_SESSION_ID', value => 'bWyYkfgu:76.19.215.210', },
	],
	'cookies method properly parses cookie header',
);

is(
	$request->get_cookie('DL_dn_seen'),
	1,
	'get_cookie() -- get real cookie value by name'
);

is(
	$request->get_cookie('not_cookie'),
	undef,
	'get_cookie() -- failure to return cookie by name returns undef'
);

cmp_ok(
	$request->method,
	'eq',
	'get',
	'method() -- get request',
);

is_deeply(
	{ $request->get_variables },
	{ %cgi },
	'get_variables() -- get request',
);

is_deeply(
	{ $request->post_variables },
	{},
	'post_variables() -- get request',
);

$request->headers->{REQUEST_METHOD} = 'POST';
cmp_ok(
	$request->method,
	'eq',
	'post',
	'method() -- post request',
);

is_deeply(
	{ $request->get_variables },
	{},
	'get_variables() -- post request',
);

is_deeply(
	{ $request->post_variables },
	{ %cgi },
	'post_variables() -- post request',
);

ok(
	! $request->https_on,
	'https_on() -- false',
);

$request->headers->{HTTPS} = 1;
ok(
	$request->https_on,
	'https_on() -- true',
);

delete $env{HTTP_COOKIE};
$request->headers( \%env );

is_deeply(
	[ $request->cookies() ] ,
	[],
	'cookies() -- empty cookie header',
);

