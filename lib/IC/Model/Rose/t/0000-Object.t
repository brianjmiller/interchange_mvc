#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 14;

my ($class, $subclass);
BEGIN {
    $class = 'IC::Model::Rose::Object';
    use_ok($class);
}

package Bogus::DB;
use Rose::DB;
use base qw(Rose::DB);
__PACKAGE__->register_db(
    domain      => 'bogus',
    type        => 'bogus',
    driver      => 'Pg',
    database    => 'bogus',
    username    => 'bogus',
    password    => 'bogus',
);
__PACKAGE__->default_domain('bogus');
__PACKAGE__->default_type('bogus');

package Bogus::Model;
use base $class;
$subclass = __PACKAGE__;
__PACKAGE__->meta->table('bogus');
__PACKAGE__->meta->columns(
    id  => { type => 'integer', not_null => 1 },
    foo => { type => 'varchar', length => 32, not_null => 1 },
);
__PACKAGE__->meta->primary_key_columns([ 'id' ]);
__PACKAGE__->meta->initialize;
__PACKAGE__->make_manager_package;

sub init_db {
    return Bogus::DB->new;
}

package main;

my $manager = $subclass . '::Manager';

{
    my $check = 0;
    sub check { return $check }
    sub reset_check { $check = 0 };
    sub touch { $check++ }
}

for my $item (
    [qw( get_instances find )],
    [qw( update_instances set )],
    [qw( get_instances_count count )],
    [qw( get_objects_from_sql find_by_sql )],
    [qw( delete_instances remove )],
) {
    my ($manager_sub, $subclass_sub) = @$item;
    ok(
        UNIVERSAL::can($manager, $manager_sub),
        "manager class gets $manager_sub",
    );
    
    {
        my $name = "$manager\::$manager_sub";
        no strict 'refs';
        no warnings;
        *$name = \&touch;
    }

    reset_check();
    my $sub = $subclass->can($subclass_sub);
    $subclass->$sub();
    ok(
        check(),
        "$subclass_sub delegates to $manager_sub",
    );
}

my $obj = $subclass->new;
isa_ok(
    $obj,
    $subclass,
);

is(
    ($obj->can('logger') && $obj->logger) || 'no obj logger',
    (UNIVERSAL::can('IC::Log', 'logger') && IC::Log->logger) || 'no class logger',
    'logger() default behavior',
);

$obj->set_logger( IC::Log::Base->new ) if $obj->can('set_logger');
is(
    ($obj->can('logger') && $obj->logger) || 'no obj logger',
    ($obj->can('get_logger') && $obj->get_logger) || 'no get_logger',
    'logger() instance specific behavior',
);

