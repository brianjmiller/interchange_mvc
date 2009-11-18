#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use File::Spec;
use IC::Controller::Route::Helper;

use Test::More tests => 13;

# This needs to do something that would throw a Safe error if not wrapped
# by Safe::Hole
package Foo::Object;
use File::Temp qw(tempfile);
{
    my $i = 0;
    sub new {
        my $class = shift;
        my $val = $i++;
        my $self = \$val;
        bless $self, $class;
        return $self;
    }
}
sub value {
    my $self = shift;
    my $file = tempfile( UNLINK => 1);
    return $$self;
}

package main;

my $class = 'IC::View::TST';
BEGIN: {
	require_ok( 'IC::View::Base' );
	require_ok( $class );
}

my $file = __FILE__;
my $help_dir = $file;
$help_dir =~ s/\.t$//;

ok($class->handles( 'tst' ), 'handles .tst views');
ok(! $class->handles('html'), 'does not handle .html views');
ok(! $class->handles('itl'), 'does not handle .itl views');

my $obj = $class->new;
isa_ok($obj, $class);

my ($simple_view, $data_view, $helper_view, $obj_view, $obj_list_view, $obj_hash_view, $complex_obj_view)
	= map { File::Spec->catfile( $help_dir, $_ . '.tst' ) }
	qw(
		simple
		data
        helper
        single_object
        object_list
        object_hash
        complex
	)
;

$obj->render( $simple_view );
my $result = $obj->content;
chomp $result;
cmp_ok(
	$result,
	'eq',
	'This is simple',
	'render: simple view with no data',
);

$obj->render( $data_view, { x => 1, y => 2, }, );
$result = $obj->content;
chomp $result;
cmp_ok(
	$result,
	'eq',
	"x: 1\ny: 2",
	'render: data view with variable marshaling',
);

$obj->helper_modules( [qw( IC::Controller::Route::Helper ) ] );
$obj->render( $helper_view, { href => 'http://www.google.com' } );
$result = $obj->content;
chomp $result;
cmp_ok(
    $result,
    'eq',
    'http://www.google.com',
    'render: helper method url()',
);

my $wrap_obj = Foo::Object->new;
$obj->render( $obj_view, { object => $wrap_obj } );
$result = $obj->content;
chomp $result;
is(
    $result,
    'object: ' . $wrap_obj->value,
    'render: basic object marshalling',
);

my @wrap_objs = map { Foo::Object->new } (1..100);
$obj->render( $obj_list_view, { objects => \@wrap_objs } );
$result = $obj->content;
chomp $result;
is(
    $result,
    'objects: ' . join(', ', map { $_->value } @wrap_objs),
    'render: object list marshalling',
);

my %wrap_objs = map { $_ => Foo::Object->new } (1..100);
$obj->render( $obj_hash_view, { objects => \%wrap_objs } );
$result = $obj->content;
chomp $result;
is(
    $result,
    'objects: ' . join(', ', map { "$_ => " . $wrap_objs{$_}->value } sort { $a <=> $b } keys %wrap_objs),
    'render: object hash marshalling',
);

my ($a, $b, $c, $d, $e);
@wrap_objs = (
    {
        1 => $a = Foo::Object->new,
    },
    $b = Foo::Object->new,
    'blah',
    [
        [
            $c = Foo::Object->new,
            $d = Foo::Object->new,
        ],
        $e = Foo::Object->new,
    ],
);

use IC::Log;
$result = $obj->render( $complex_obj_view, { objects => \@wrap_objs, logger => IC::Log->logger } );
$result = $obj->content;
is($result, sprintf(<<'EOL', map { $_->value } ($a, $b, $c, $d, $e) ), 'render: complex data marshalling');
[
  {
    1 => %d
  }
  %d
  blah
  [
    [
      %d
      %d
    ]
    %d
  ]
]
EOL

1;
