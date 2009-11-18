#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 3);
use IC::Controller;
use IC::Controller::RenderHelper;

eval {
    render( view => 'simple', context => { a => 'a', } );
};
ok(
    $@,
    'render(): exception thrown if no controller present',
);

my $path = __FILE__;
$path =~ s/\.t$//;
IC::Controller::HelperBase->bind_to_controller(
    IC::Controller->new(
        view_path => $path,
    )
);

SKIP: {
    skip( 'Unable to create bound controller for render tests!', 2, )
        unless defined IC::Controller::HelperBase->controller
    ;

    cmp_ok(
        render( view => 'simple', context => { a => 'a', }, ),
        '=~',
        qr{^a: a\s*$},
        'render(): basic render() call',
    );

    cmp_ok(
        render( view => 'simple', context => {a => 'a',}, layout => 'bogus', ),
        '=~',
        qr{^a: a\s*$},
        'render(): layout filtered out',
    );
    
=cut

Oops... this is inappropriate to do anywhere but within the controller test itself...
    cmp_ok(
        render( view => 'nested', context => { a => 'b', }, ),
        '=~',
        qr{},
        'render(): nested call',
    );
    
=cut

}

