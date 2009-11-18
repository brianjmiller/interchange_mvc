#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use Test::More qw(no_plan);
use File::Spec;
use IC::Controller::Route::Helper;

my $class = 'IC::View';
BEGIN: {
	require_ok( $class );
}

my $dir = __FILE__;
$dir =~ s/\.t$//;
$dir = File::Spec->rel2abs($dir);

my $view_obj = $class->new( base_path => $dir, );

cmp_ok(
	$view_obj->find_view_file( 'simple.html' ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.html' ) ),
	'find_view_file: basic',
);

cmp_ok(
	$view_obj->find_view_file( 'simple.tst' ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.tst' ) ),
	'find_view_file: basic',
);

cmp_ok(
	$view_obj->find_view_file( 'simple' ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.' . $view_obj->default_extension ) ),
	'find_view_file: built-in default extension',
);

# change default extension
my $orig_ext = $view_obj->default_extension;
$view_obj->default_extension('zzz');
cmp_ok(
	$view_obj->find_view_file( 'simple' ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.html' ) ),
	'find_view_file: first valid extension known to View::Base with invalid default extension',
);

$view_obj->default_extension('pbm');
cmp_ok(
	$view_obj->find_view_file( 'simple' ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.pbm' ) ),
	'find_view_file: default extension that is not html',
);

$view_obj->default_extension($orig_ext);

my $file = File::Spec->canonpath( File::Spec->catfile( $dir, 'simple.tst' ) );
cmp_ok(
	$view_obj->find_view_file( $file ),
	'eq',
	$file,
	'find_view_file: absolute path',
);

$file = File::Spec->canonpath( File::Spec->catfile( $dir, 'simple' ) );
cmp_ok(
	$view_obj->find_view_file( $file ),
	'eq',
	$file . '.' . $view_obj->default_extension,
	'find_view_file: absolute path with default extension',
);

cmp_ok(
	$view_obj->identify_file( 'simple' ),
	'eq',
	$view_obj->find_view_file( 'simple' ),
	'identify_file: basic use',
);


cmp_ok(
	$view_obj->identify_file( $file ),
	'eq',
	$view_obj->find_view_file( $file ),
	'identify_file: basic use with absolute paths',
);

cmp_ok(
	$view_obj->identify_file( [ 'simple.tst', 'simple.html' ] ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.tst' ) ),
	'identify_file: first match wins',
);

cmp_ok(
	$view_obj->identify_file( [ 'simple', 'simple.tst' ] ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.' . $view_obj->default_extension ) ),
	'identify_file: first match wins with default extension',
);

cmp_ok(
	$view_obj->identify_file( [ 'bogus.tst', 'simple.tst', 'simple.html', ] ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.tst' ) ),
	'identify_file: bogus files skipped, subsequent match wins',
);

cmp_ok(
	$view_obj->identify_file( [ 'bogus.tst', 'simple', 'simple.tst', ] ),
	'eq',
	clean( File::Spec->catfile( $dir, 'simple.html' ) ),
	'identify_file: bogus files skipped, subsequent match wins with default extension',
);

my %type_map = (
	tst => 'IC::View::TST',
	html => 'IC::View::ITL',
	itl => 'IC::View::ITL',
);

diag('checking type mapping...');
for my $type ( sort { $a cmp $b } keys %type_map ) {
	my $obj;
	eval {
		$obj = $view_obj->get_view_object( "simple.$type" );
	};
	isa_ok(
		$obj,
		$type_map{$type},
	);
}

diag('performing basic rendering');
my $result = $view_obj->render('simple.tst');
chomp $result;
cmp_ok(
	$result,
	'eq',
	'TST',
	'render: .tst file (no marshal)',
);

$result = $view_obj->render('simple.html');
chomp $result;
cmp_ok(
	$result,
	'eq',
	'ITL',
	'render: .html file (no marshal)',
);

$result = $view_obj->render('data.tst', { data => 'kidney stones', });
chomp $result;
cmp_ok(
	$result,
	'eq',
	'You passed: kidney stones',
	'render: .tst file (data marshaled)',
);

diag('helper module use');
$view_obj->helper_modules( [qw( IC::Controller::Route::Helper ) ] );
$result = $view_obj->render('helper.tst', { href => 'http://www.endpoint.com', } );
chomp $result;
cmp_ok(
    $result,
    'eq',
    'url() -- http://www.endpoint.com',
    'render: helper module function url()',
);

sub clean {
	return File::Spec->canonpath( File::Spec->rel2abs( shift ) );
}

1;
