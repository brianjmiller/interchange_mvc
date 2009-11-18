#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More tests => 7;
use URI::Escape qw/uri_escape_utf8 uri_unescape/;
use Data::Dumper qw/Dumper/;

package Foo;
use IC::Controller;
use base qw/IC::Controller/;
BEGIN {
    Foo->registered_name('foo');
}

package main;

my $module;
BEGIN {
    $module = 'IC::Controller::Route::Test';
    use_ok($module);
}

# verify that an arbitrarily complex data structure is converted
# into and out of a path.
my $model_params = {
    foo => [
        { blah => 'blee', one => 'two', foo => 'foof' },
        [qw( binky bonky boo )],
        [ [ [qw( pinky ponky poo )], {qw( asfasdf aodifjsd 3498asdnf 3485 )} ], {} ],
    ],
    bomp => 'blah',
    blee => [qw( zaz zaz zazaazaaaz)],
    dance_of_the => 'sugar plum fairies',
};

my $model_stream = uri_escape_utf8(Dumper($model_params));

my $result = $module->params_to_path( {%$model_params} );
ok(
    defined($result->{parameters}) && !ref($result->{parameters}),
    'params_to_path() creates a string representing the parameters',
);

is_deeply(
    eval( uri_unescape($result->{parameters}) ),
    $model_params,
    'params_to_path() params string evals to data structure'
);

is_deeply(
    $module->params_from_path( { parameters => $model_stream }, ),
    $model_params,
    'params_from_path()',
);

my $clone_params = eval Dumper($model_params);
$clone_params->{action} = 'foo';
is_deeply(
    $module->params_from_path( { action => 'foo', parameters => $model_stream } ),
    $clone_params,
    'params_from_path() preserves special parameters',
);

is(
    $module->generate_path(
        controller  => 'foo',
        action      => 'bar',
        %$model_params,
    ),
    "foo/bar/$result->{parameters}",
    'generate_path()',
);

$clone_params->{action} = 'bar';
$clone_params->{controller} = 'foo';
is_deeply(
    $module->parse_path("foo/bar/$result->{parameters}"),
    $clone_params,
    'parse_path()',
);

