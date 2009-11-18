#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 57;

my ($class, $base_class);

BEGIN {
    $class = 'IC::Log::Interchange';
    $base_class = 'IC::Log::Base';
    use_ok($class);
}

my $obj = $class->new;

isa_ok(
    $obj,
    $class
);

isa_ok(
    $obj,
    $base_class,
);

is(
    $obj->can('_fallback_log'),
    $base_class->can('_fallback_log'),
    "_fallback_log() is the same mechanism as in $base_class",
);

{
    my ($level, $msg, $fallback);
    my $fallback_log_catcher = sub {
        my ($self, $p, $m) = @_;
        $level = $p;
        $msg = $m;
        $fallback = 1;
        return 1;
    };

    sub reset_test {
        $level = $msg = $fallback = undef;
    }

    sub fallback { return $fallback }
    
    sub level { return $level }

    sub message { return $msg }
    
    sub log_it { ($level, $msg) = @_; }
    
    no strict 'refs';
    no warnings;
    my $name = $class . '::_fallback_log';
    *$name = $fallback_log_catcher;
}

reset_test();
$obj->log('error', 'blah');
ok(fallback(), '_fallback_log used when no ::logError in place');
is(
    message(),
    'blah',
    '_fallback_log gets message properly',
);

reset_test();
$obj->log('debug', 'foo');
ok(
    fallback(),
    '_fallback_log used when no ::logError in place',
);
is(
    message(),
    'foo',
    '_fallback_log() gets message properly',
);

reset_test();
$obj->quiet_fallback(1);
$obj->log('error', 'blah');
ok(
    !(fallback() || message() || level()),
    'quiet_fallback() deactivates fallback logging',
);
$obj->quiet_fallback(0);

{
    my $err = sub {
        return log_it('error', @_);
    };

    my $dbg = sub {
        return log_it('debug', @_);
    };

    no warnings;
    *::logDebug = $dbg;
    *::logError = $err;
}

my $error_priority = $obj->priority('error');
my $debug_priority = $obj->priority('debug');
my $warning_priority = $obj->priority('warning');
for my $level (0..$debug_priority) {
    my $expected_level = ($level <= $warning_priority) ? $error_priority : $debug_priority;
    $level = $obj->priority_name($level);
    reset_test();
    $obj->log($level, 'some string %s', 'foo');
    ok(!fallback(), '_fallback_log() not used when ::logError/::logDebug defined');
    is(message(), uc($level) . ': some string foo', "log($level) message properly prepared");
    is(
        $obj->priority_name(level()),
        $obj->priority_name($expected_level),
        "log($level) registered at proper level",
    );

    reset_test();
    $obj->quiet_fallback(1);
    $obj->log($level, 'with fallback quiet');
    ok(!fallback(), '_fallback_log() usage unaffected by fallback_quiet property');
    is(message(), uc($level) . ': with fallback quiet', 'standard logging unaffected by fallback_quiet');
    $obj->quiet_fallback(0);
    
    reset_test();
    my $sub = $obj->can($level);
    $obj->$sub('my message') if $sub;
    is(
        message(),
        uc($level) . ': my message',
        "$level() properly dispatched/prefixed",
    );
}


