#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use File::Temp qw/tempdir/;

use Test::More tests => 87;

my ($class);
BEGIN {
    $class = 'IC::Log::Base';
    use_ok($class);
}

package Bogus::Log;
use base ($class);
{
    my @stack;
    sub log {
        my $self = shift;
        @stack = ();
        return $self->SUPER::log(@_);
    }

    sub validate_priority {
        push @stack, 'validate_priority';
        return 1;
    }
    
    sub _log {
        my $self = shift;
        push @stack, '_log';
        return 1;
    }

    sub format_message {
        push @stack, 'format_message';
        return 1;
    }

    sub stack {
        return @stack;
    }
}

package main;

my $obj = $class->new;
isa_ok(
    $obj,
    $class,
);

# Verify basic operation of IC::Log::Base logging, formatting, and priority
# dispatching functions.

my @priorities = qw/
    emerg
    alert
    crit
    error
    warning
    notice
    info
    debug
/;

for my $i (0..$#priorities) {
    cmp_ok(
        $obj->priority($priorities[$i]),
        '==',
        $i,
        "priority($priorities[$i]) maps to correct numeric value"
    );
    cmp_ok(
        $obj->validate_priority($priorities[$i]),
        '==',
        $i,
        "validate_priority($priorities[$i]) maps to correct numeric value"
    );
    cmp_ok(
        $obj->priority($i),
        '==',
        $i,
        "priority($i) identity function",
    );
    cmp_ok(
        $obj->validate_priority($i),
        '==',
        $i,
        "validate_priority($i) identity function",
    );
    is(
        $obj->priority_name($i),
        $priorities[$i],
        "priority_name($i) maps to correct name",
    );
    is(
        $obj->priority_name($priorities[$i]),
        $priorities[$i],
        "priority_name($priorities[$i]) identity function",
    );
}

eval { $obj->validate_priority( scalar(@priorities) ) };
cmp_ok(
    $@,
    '=~',
    qr{invalid logging level}i,
    'validate_priority() throws exception on bad numeric level',
);

eval { $obj->validate_priority( 'foochungchomper' ) };
cmp_ok(
    $@,
    '=~',
    qr{invalid logging level}i,
    'validate_priority() throws exception on bad level name',
);

is(
    $obj->format_message('some message'),
    'some message',
    'format_message() simple string',
);

is(
    $obj->format_message('some %s message %d', 'other', 1),
    'some other message 1',
    'format_message() sprintf support'
);

for my $level (@priorities) {
    reset_log();
    $obj->_log($level, 'some message'),
    is(
        read_log(),
        uc($level) . ": some message\n",
        "_log($level) message construction",
    );
    reset_log();
    $obj->_fallback_log($level, 'some other message'),
    is(
        read_log(),
        uc($level)  . ": some other message\n",
        "_fallback_log($level) same as _log($level)",
    );
    reset_log();
    $obj->log($level, '%s %d', 'foo', 2);
    is(
        read_log(),
        uc($level) . ": foo 2\n",
        "log($level) message fully formatted",
    );
    reset_log();
    my $sub = $obj->can($level);
    $obj->$sub('a message of %s', 'peace') if $sub;
    is(
        read_log(),
        uc($level) . ": a message of peace\n",
        "$level() helper method",
    );
}

$obj = Bogus::Log->new;
$obj->log('info', 'foo');
is_deeply(
    [ $obj->stack ],
    [qw/ validate_priority format_message _log /],
    'log() order of delegation, subclassing',
);

my $dir;
sub set_log_dir {
    $dir = tempdir( CLEANUP => 1 ) if !defined($dir);
}

sub read_log {
    set_log_dir();
    open my $in, '<', "$dir/log" or die "Error opening log file for read: $!\n";
    my $out;
    while (<$in>) {
        $out .= $_;
    }
    close $in;
    return $out;
}

sub reset_log {
    set_log_dir();
    close STDERR or die "Error closing STDERR for reset: $!\n";
    open STDERR, '>', "$dir/log" or die "Error opening STDERR for write: $!\n";
    return;
}
