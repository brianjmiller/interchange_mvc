#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 8;

# Bogus::Log::Default: a user of IC::Log::Logger that
# simply relies on defaults
package Bogus::Log::Default;
use IC::Log::Logger;
sub get_logger { return; }

# Bogus::Log::Default::Override: user of IC::Log::Logger that
# overrides the default setting
package Bogus::Log::Default::Override;
use IC::Log::Logger qw/logger/;
{
    my $log = IC::Log::Base->new;
    sub get_logger_default { return $log }
}

# Bogus::Log::Object: get_logger returns an actual object
# instance that does log() rather than logger()
package Bogus::Log::Object;
use IC::Log::Logger;
{
    my $log = IC::Log::Base->new;
    sub get_logger { return $log }
}

# Bogus::Log::Package: get_logger returns a package that
# does logger() rather than log()
package Bogus::Log::Package;
use IC::Log::Logger;
sub get_logger { return 'IC::Log::Bogus' }

# IC::Log::Bogus: a derivative of IC::Log that
# sets its own independent logger object for testing
# of Bogus::Log::Package
package IC::Log::Bogus;
use base qw/IC::Log/;
__PACKAGE__->set_logger( IC::Log::Base->new );

package main;

my $object_class = 'IC::Log::Base';

is( IC::Log::Logger::get_logger_default(), 'IC::Log', 'get_logger_default()' );

cmp_ok(
    Bogus::Log::Default->logger,
    '==',
    IC::Log->logger,
    'logger() defaults to IC::Log->logger',
);

isa_ok(
    Bogus::Log::Default->logger,
    $object_class,
);

cmp_ok(
    Bogus::Log::Object->logger,
    '==',
    Bogus::Log::Object->get_logger,
    'logger() with object result',
);

isa_ok(
    Bogus::Log::Object->logger,
    $object_class,
);

cmp_ok(
    Bogus::Log::Package->logger,
    '==',
    Bogus::Log::Package->get_logger->logger,
    'logger() with package'
);

isa_ok(
    Bogus::Log::Package->logger,
    $object_class,
);

cmp_ok(
    Bogus::Log::Default::Override->logger,
    '==',
    Bogus::Log::Default::Override->get_logger_default,
    'logger() with subclass-overriden get_logger_default',
);

