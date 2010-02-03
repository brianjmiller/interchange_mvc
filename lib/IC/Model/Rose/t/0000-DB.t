#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;

use Test::More (tests => 12);
use Test::Exception;

my $class;
BEGIN {
    use_ok $class = 'IC::Model::Rose::DB';
}

# We trust basic Rose configuration works fine;
# this test is concerned with commit callbacks.
my (%counter, %callback, @stack);
sub reset_counters {
    %counter = (a => 0, b => 0, c => 0);
    @stack = ();
    return;
}

%callback = map {
    my $key = $_;
    $key => sub { $counter{$key}++; push @stack, $key; };
} qw(a b c);

my $db = $class->new;

is_deeply(
    [$db->commit_callbacks],
    [],
    'commit_callbacks initialized to empty array',
);

throws_ok {
    $db->add_commit_callbacks($callback{a});
} qr(must be in a transaction), 'add_commit_callbacks() fails outside a transaction';

$db->begin_work;

$db->add_commit_callbacks(@callback{qw(a c)});
is_deeply(
    [$db->commit_callbacks],
    [@callback{qw(a c)}],
    'add_commit_callbacks() adds callbacks in specified order',
);

$db->add_commit_callbacks($callback{b});
is_deeply(
    [$db->commit_callbacks],
    [@callback{qw(a c b)}],
    'add_commit_callbacks() appends rather than setting',
);

$db->rollback;
is_deeply(
    [$db->commit_callbacks],
    [],
    'rollback() clears callbacks',
);

reset_counters();
$db->begin_work;
$db->add_commit_callbacks(@callback{qw(b a c)});
$db->commit;
is_deeply(
    [$db->commit_callbacks],
    [],
    'commit() clears callbacks',
);
is_deeply(
    \@stack,
    [qw(b a c)],
    'commit() executes callbacks in order',
);

reset_counters();
$db->do_transaction(
    sub {
        $db->add_commit_callbacks(@callback{qw(c b a)});
        return 1;
    }
);
is_deeply(
    \@stack,
    [qw(c b a)],
    'do_transaction() executes callbacks in order on success',
);
is_deeply(
    [$db->commit_callbacks],
    [],
    'do_transaction clears callbacks on success',
);

reset_counters();
$db->do_transaction(
    sub {
        $db->add_commit_callbacks(values %callback);
        die;
    }
);
is_deeply(
    \@stack,
    [],
    'do_transaction() does not execute callbacks on failure',
);
is_deeply(
    [$db->commit_callbacks],
    [],
    'do_transaction() clears calbacks on failure',
);
