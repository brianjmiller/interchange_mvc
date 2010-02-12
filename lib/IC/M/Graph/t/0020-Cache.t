#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 10;
use Test::Exception;

my $class;
BEGIN {
    $class = 'IC::M::Graph::Cache';
    use_ok $class;
}

# some test packages that implement various aspects of the interface.
package ThisTest::NoBuild;

sub retrieve_cache {}
sub clear_cache {}
sub fetch_relations {}
use Moose;
Test::Exception::throws_ok {
    with $class;
} qr(method 'build_cache'), 'build_cache() method is required';

package ThisTest::NoClear;

sub retrieve_cache {}
sub build_cache {}
sub fetch_relations {}
use Moose;
Test::Exception::throws_ok {
    with $class;
} qr(method 'clear_cache'), 'clear_cache() method is required';

package ThisTest::NoRetrieve;

sub clear_cache {}
sub build_cache {}
sub fetch_relations {}
use Moose;
Test::Exception::throws_ok {
    with $class;
} qr(method 'retrieve_cache'), 'retrieve_cache() method is required';

package ThisTest::All;

# lexically-limited "private" vars
{
    my $cache;
    my %calls;

    sub clear_cache {
        $calls{clear_cache}++;
        $cache = undef;
    }

    sub build_cache {
        my ($self, $data) = @_;
        $calls{build_cache}++;
        $cache = $data;
    }

    sub retrieve_cache {
        $calls{retrieve_cache}++;
        return $cache;
    }

    sub fetch_relations {
        $calls{fetch_relations}++;
        return [
            [1, undef],
            [2, 1],
            [3, 1],
            [4, 2],
            [5, 4],
        ];
    }

    sub calls { return \%calls }
}

use Moose;
Test::Exception::lives_ok(
    sub {
        with $class;
    },
    'mix-in succeeds if all required methods are present',
);

package main;

my $obj = ThisTest::All->new;
my $no_ref = $obj->no_referers;
is_deeply(
    { map { $_ => ThisTest::All->calls->{$_} } qw(build_cache retrieve_cache fetch_relations) },
    { build_cache => 1, retrieve_cache => 1, fetch_relations => 1 },
    'initialize() attempts to retrieve cache, fetches relations, and builds cache',
);
is_deeply(
    $no_ref,
    [3, 5],
    'role provides the graph basic role operations',
);

$obj = ThisTest::All->new;
my $cached_no_ref = $obj->no_referers;
is_deeply(
    { map { $_ => ThisTest::All->calls->{$_} } qw(build_cache retrieve_cache fetch_relations) },
    { build_cache => 1, retrieve_cache => 2, fetch_relations => 1 },
    'subsequent initialize() retrieves cache, skips build and relation fetch',
);

diag('note: this test is for minimal consistency');
is_deeply(
    $no_ref,
    $cached_no_ref,
    'cached data appears consistent with uncached',
);

$obj = ThisTest::All->new;
$obj->clear_cache;
$obj->no_referers;
is_deeply(
    { map { $_ => ThisTest::All->calls->{$_} } qw(build_cache retrieve_cache fetch_relations) },
    { build_cache => 2, retrieve_cache => 3, fetch_relations => 2 },
    'post-clear_cache initialize() again fetches relations and builds cache after failed cache retrieve',
);

