#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use Test::More (tests => 6);

use IC::Controller;

package Bogus::Test::HelperA;
use IC::Controller::HelperBase;
use Exporter;
use base qw(Exporter IC::Controller::HelperBase);
@Bogus::Test::HelperA::EXPORT_OK = qw( &a $b @c %d e );
1;
package Bogus::Test::HelperB;
use IC::Controller::HelperBase;
use Exporter;
use base qw(Exporter IC::Controller::HelperBase);
@Bogus::Test::HelperB::EXPORT = qw( &f $g @h %i j );
1;
package Bogus::Test::HelperC;
use IC::Controller::HelperBase;
use base qw(IC::Controller::HelperBase);
package main;

cmp_ok(
    join(' ', Bogus::Test::HelperA->export_symbols),
    'eq',
    '&a $b @c %d &e',
    'EXPORT_OK symbol list',
);

cmp_ok(
    join(' ', Bogus::Test::HelperB->export_symbols),
    'eq',
    '&f $g @h %i &j',
    'EXPORT symbol list',
);

cmp_ok(
    join(' ', Bogus::Test::HelperC->export_symbols),
    'eq',
    '',
    'No symbol list',
);

my $controller = IC::Controller->new;
IC::Controller::HelperBase->bind_to_controller( $controller );
cmp_ok(
    IC::Controller::HelperBase->controller,
    '==',
    $controller,
    'bind_to_controller()/controller() set/get',
);

eval {
    Bogus::Test::HelperA->bind_to_controller( $controller );
};
ok(
    $@,
    'bind_to_controller(): throws exception if not IC::Controller::HelperBase',
);

cmp_ok(
    Bogus::Test::HelperB->controller,
    '==',
    $controller,
    'bind_to_controller()/controller() inheritance',
);

1;
