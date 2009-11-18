#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 26);

my $class = 'IC::Controller::Route::Binding';

BEGIN: {
    use_ok($class);
}

my $binding = $class->new;
isa_ok(
    $binding,
    $class,
);

for my $attrib (qw(controller_parameters name_map parameters)) {
    my $sub = $binding->can($attrib);
    is_deeply(
        $binding->$sub(),
        {},
        $attrib . '(): defaults to empty hash',
    );

    my %test_hash = ( foo => 'bar' );
    $binding->$sub( { %test_hash } );
    is_deeply(
        $binding->$sub,
        \%test_hash,
        $attrib . '(): accepts hash',
    );

    eval {
        $binding->$sub( [] );
    };
    
    ok(
        $@,
        $attrib . '(): rejects non-hash',
    );
}

is_deeply(
    $binding->url_names,
    [],
    'url_names(): defaults to empty array',
);

my @test_array = qw( foo bar bah );
$binding->url_names( [ @test_array ] );
is_deeply(
    $binding->url_names,
    \@test_array,
    'url_names(): accepts array',
);

eval {
    $binding->url_names( {} );
};
ok(
    $@,
    'url_names(): rejects non-array',
);

$binding = $class->new;
is_deeply(
    $binding->url_parameters,
    {},
    'url_parameters(): empty set',
);
is_deeply(
    $binding->get_parameters,
    {},
    'get_parameters(): empty set',
);

my %params = qw(
    a a
    b b
    c c
    d d
    e e
    f f
);

$binding->parameters( { %params } );
is_deeply(
    $binding->url_parameters,
    {},
    'url_parameters(): empty if url_names empty',
);
is_deeply(
    $binding->get_parameters,
    \%params,
    'get_parameters(): all params if url_names empty',
);

$binding->url_names( [qw( a ae b c )] );
is_deeply(
    $binding->url_parameters,
    {qw( a a b b c c )},
    'url_parameters(): simple parameters',
);
is_deeply(
    $binding->get_parameters,
    {qw( d d e e f f )},
    'get_parameters(): simple parameters',
);

$binding->name_map({qw(
    a ae
    d dee
)});
is_deeply(
    $binding->url_parameters,
    {qw( ae a b b c c )},
    'url_parameters(): with name mapping',
);
is_deeply(
    $binding->get_parameters,
    {qw( dee d e e f f )},
    'get_parameters(): with name mapping',
);

$binding->controller_parameters({qw( x x y y )});
$binding->url_names( [ @{$binding->url_names}, 'x', ] );
is_deeply(
    $binding->url_parameters,
    {qw( ae a b b c c x x )},
    'url_parameters(): with controller parameters',
);
is_deeply(
    $binding->get_parameters,
    {qw( dee d e e f f y y )},
    'get_parameters(): with controller parameters',
);

$binding->controller_parameters({qw( b c_b e c_e )});
is_deeply(
    $binding->url_parameters,
    {qw( ae a b c_b c c )},
    'url_parameters(): widget/controller name collision',
);
is_deeply(
    $binding->get_parameters,
    {qw( dee d e c_e f f )},
    'get_parameters(): widget/controller name collision',
);

