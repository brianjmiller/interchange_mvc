#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use Data::Dumper;

use Test::More tests => 15;

my $class = 'IC::View::ITL';

BEGIN: {
	require_ok(qw( IC::View::Base ));
	require_ok( $class );
}

my $obj = $class->new;
isa_ok( $obj, $class, );

ok($obj->handles( 'itl' ));
ok($obj->handles( 'html' ));
ok( ! $obj->handles('tst') );

my $template = 'foo[comment]blahblah[/comment]bar';

$obj->render( $template );
cmp_ok(
	$obj->content,
	'eq',
	'foobar',
	'simple rendering',
);

# Use a tied hash to test marshaling
package Bogus::Test::Hash;

use Tie::Hash;
our @ISA = qw(Tie::StdHash);
sub STORE {
	my ($self, $key, $value) = @_;
	push @Bogus::Test::Hash::assigns, "$key: $value";
	$self->{$key} = $value;
}

sub DELETE {
	my ($self, $key) = @_;
	push @Bogus::Test::Hash::deletes, $key;
	delete $self->{$key};
}

1;

package main;

my %stash;
tie %stash, 'Bogus::Test::Hash';
$Vend::Interpolate::Stash = \%stash;

$stash{foo} = 'bar';
$stash{blee} = 'blah';

my %original = %stash;
my ($deletes, $assigns) = (\@Bogus::Test::Hash::deletes, \@Bogus::Test::Hash::assigns);

clear_info();

$obj->render( $template, {} );
ok(! @$deletes, 'empty marshal: no deletes',);
ok(! @$assigns, 'empty marshal: no assigns',);
is_deeply( \%stash, \%original, 'empty_marshal: stash space restored', );

clear_info();

$obj->render( $template, { a => 'b' } );
ok((@$assigns == 1 and $assigns->[0] eq 'a: b'), 'simple marshal: assignment');
ok((@$deletes == 1 and $deletes->[0] eq 'a'), 'simple marshal: deletes');
is_deeply( \%stash, \%original, 'simple marshal: stash space restored', );

clear_info();

$obj->render( $template, { foo => 'new' } );
is_deeply( $assigns, [ 'foo: new', 'foo: bar', ], 'override marshal: assignment and restore');
is_deeply( \%stash, \%original, 'override marshal: stash space restored', );

clear_info();

sub clear_info {
	@Bogus::Test::Hash::assigns = @Bogus::Test::Hash::deletes = ();
}

1;
