#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use IC::Cache;

use Test::More tests => 20;
use Test::Exception;

my $class;
BEGIN {
    use_ok($class = 'IC::M::Role::Graph');
}

# regrettably, we need the entire graph of relationships
# here in the test.
my $db = IC::Model::Rose::Object->init_db;
my $set = $db->dbh->selectall_arrayref(
    q{
        SELECT
            r.id,
            r.display_label,
            h.has_role_id
        FROM
            ic_roles r
        LEFT JOIN ic_roles_has_roles h ON h.role_id = r.id
    }
);

my (%map, %referenced, %name, %leaf);
for my $node (@$set) {
    my $items;
    unless ($items = $map{$node->[0]}) {
        $items = $map{$node->[0]} = {};
        $referenced{$node->[0]} ||= {};
        $name{$node->[0]} = $node->[1];
        $leaf{$node->[0]}++;
    }
    if (defined $node->[2]) {
        $referenced{$node->[2]} ||= {};
        $items->{$node->[2]}++;
        delete $leaf{$node->[2]};
        $referenced{$node->[2]}->{$node->[0]}++;
    }
}

sub gather_relations {
    my $map = shift;
    my @set = @_;
    my @result;
    my %seen;
    do {
        my @candidates = grep { !$seen{$_}++ and exists $map->{$_} } @set;
        push @result, \@candidates if @candidates;
        @set = map { keys %$_ } @$map{@candidates};
    }
    while @set;
    return @result;
}

sub gather_references {
    return gather_relations(\%map, @_);
}

sub gather_referencers {
    return gather_relations(\%referenced, @_);
}

BAIL_OUT('graph is insufficiently deep for testing!')
    unless grep { gather_references($_) > 3 } keys %leaf;

#use Data::Dumper;
#diag(Dumper(map { [ @name{@$_} ] }gather_referencers(3)));

# require database handle
throws_ok {
    $class->new;
} qr(required), 'db attribute is required';

# should use database handle provided
# note that this is supposed to be in memcached, so flush the cache
my $cache = IC::Cache->new;
$cache->flush_all();
my $tempdb = IC::Model::Rose::DB->new(override_singleton => 1);
$tempdb->dbh->disconnect;
my $graph = $class->new(db => $tempdb);
throws_ok {
    $graph->initialize_map;
} qr(disconnected handle), 'initialize_map uses the database handle provided';

# list of unreferenced ids should be the same
$cache->flush_all();
$graph = $class->new(db => $db);
is_deeply(
    $graph->no_referers,
    [ sort {$a <=> $b} grep { !keys(%{$referenced{$_}}) } keys %referenced ],
    'no_referers returns sorted list of ids of unreferenced nodes',
);

# list of no-references ids should be the same
is_deeply(
    $graph->no_references,
    [ sort {$a <=> $b} grep { !keys(%{$map{$_}}) } keys %map ],
    'no_references returns sorted list of ids of nodes with no outbound references',
);

# non-exist node should have no referers and no references
is_deeply(
    $graph->referers('xyz'),
    [],
    'referers gives empty set for non-existent node',
);

is_deeply(
    $graph->references('xyz'),
    [],
    'references gives empty set for non-existent node',
);

is_deeply(
    $graph->explode('xyz'),
    [],
    'explode gives empty set for non-existent node',
);

# compare generations for unreferenced ids
is_deeply(
    [
        map {
            [ map { [sort {$a <=> $b} @$_] } @{$graph->references($_)} ]
        }
        @{$graph->no_referers}
    ],
    [
        map {
            [map { [sort {$a <=> $b} @$_] } gather_references($_)]
        }
        sort {$a <=> $b} 
        grep { !keys(%{$referenced{$_}}) }
        keys %referenced
    ],
    'references() structures consistent across all unreferenced nodes',
);

# compare generations for no-reference ids
is_deeply(
    [
        map {
            [ map { [sort {$a <=> $b} @$_] } @{$graph->referers($_)} ]
        }
        @{$graph->no_references}
    ],
    [
        map {
            [map { [sort {$a <=> $b} @$_] } gather_referencers($_)]
        }
        sort {$a <=> $b} 
        grep { !keys(%{$map{$_}}) }
        keys %map
    ],
    'referers() structures consistent across all no-reference nodes',
);

# pick an unreferenced node that has at least 3 generations of references.
my $subgraph;
for my $item (@{ $graph->no_referers }) {
    my $tmp = $graph->references($item);
    # must have:
    # - four generations (including identity generation)
    # - at least 2 members in first and second generation
    # - unique members in first and second generation
    next unless @$tmp >= 4
        and @{$tmp->[1]} >= 2
        and @{$tmp->[2]} >= 2;

    my %id = map { $_ => 1 } @{$tmp->[1]}, @{$tmp->[2]};
    next unless scalar(keys %id) == (@{$tmp->[1]} + @{$tmp->[2]});
    $subgraph = $tmp;
    last;
}
BAIL_OUT('Failed to find appropriate subgraph for generation checks!') unless $subgraph;

is_deeply(
    $graph->has_reference(
        node => $subgraph->[0][0],
        targets => [$subgraph->[0][0]],
    ),
    [],
    'a node does not has_reference() to itself',
);

is_deeply(
    $graph->has_reference(
        node => $subgraph->[0][0],
        targets => $subgraph->[1],
    ),
    $subgraph->[1],
    'has_reference() returns set of items it has',
);

is_deeply(
    [
        sort {$a <=> $b } @{$graph->has_reference(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[1]},
        @{$subgraph->[2]},
    ],
    'has_reference() combines generations by default',
);

is_deeply(
    [
        sort {$a <=> $b} @{$graph->has_reference(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
            generations => 1,
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[1]},
    ],
    'has_reference() with "generations" limits generationally',
);

is_deeply(
    [
        sort {$a <=> $b} @{$graph->has_reference(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
            generations => 2,
            exact       => 1,
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[2]},
    ],
    'has_reference with "exact" "generations" restricts generationally',
);

$subgraph = undef;
for my $item (@{ $graph->no_references }) {
    my $tmp = $graph->referers($item);
    # must have:
    # - four generations (including identity generation)
    # - at least 2 members in first and second generation
    # - unique members in first and second generation
    next unless @$tmp >= 4
        and @{$tmp->[1]} >= 2
        and @{$tmp->[2]} >= 2;

    my %id = map { $_ => 1 } @{$tmp->[1]}, @{$tmp->[2]};
    next unless scalar(keys %id) == (@{$tmp->[1]} + @{$tmp->[2]});
    $subgraph = $tmp;
    last;
}
BAIL_OUT('Failed to find appropriate subgraph for generation checks!') unless $subgraph;

is_deeply(
    $graph->has_referer(
        node => $subgraph->[0][0],
        targets => $subgraph->[1],
    ),
    $subgraph->[1],
    'has_referer() returns set of items it has',
);

is_deeply(
    [
        sort {$a <=> $b } @{$graph->has_referer(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[1]},
        @{$subgraph->[2]},
    ],
    'has_referer() combines generations by default',
);


is_deeply(
    [
        sort {$a <=> $b} @{$graph->has_referer(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
            generations => 1,
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[1]},
    ],
    'has_referer() with "generations" limits generationally',
);

is_deeply(
    [
        sort {$a <=> $b} @{$graph->has_referer(
            node => $subgraph->[0][0],
            targets => [@{$subgraph->[1]}, @{$subgraph->[2]}],
            generations => 2,
            exact       => 1,
        )}
    ],
    [
        sort {$a <=> $b}
        @{$subgraph->[2]},
    ],
    'has_referer with "exact" "generations" restricts generationally',
);

SKIP: {
    # cache checks

    skip('Memcached server does not appear to be running', 1)
        unless keys( %{ $cache->server_versions } );

    # this would die if the database is used, so living means it read from memcached.
    $db = IC::Model::Rose::DB->new(override_singleton => 1);
    $db->dbh->disconnect;
    my $cached_graph = $class->new( db => $db );
    is_deeply(
        [$cached_graph->no_references, $cached_graph->no_referers],
        [$graph->no_references, $graph->no_referers],
        'previous operations seeded the cache, and cached representation is consistent',
    );
}

