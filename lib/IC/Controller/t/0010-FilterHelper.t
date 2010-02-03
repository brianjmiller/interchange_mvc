#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 46;
use IC::Controller::FilterHelper;

use constant RAW => 0;
use constant FILTERED => 1;

my %map = (
    commify => [ '1000', '1,000.00' ],
    date_change => [ qw/1-1-07 20070101/ ],
    compress_space => ['  single   spaces    please    ', 'single spaces please'],
    null_to_space => ["null\0to\0space", 'null to space'],
    null_to_comma => ["null\0to\0comma", 'null,to,comma'],
    null_to_colons => ["null\0to\0colons", 'null::to::colons'],
    space_to_null => ['space to null', "space\0to\0null"],
    colons_to_null => ['colons::to::null', "colons\0to\0null"],
    digits_dot => [ qw/-a-z.123? .123/ ],
    namecase => [ 'JIMMY GIBLETS', 'Jimmy Giblets' ],
    name => [ 'Giblets, Jimmy', 'Jimmy Giblets' ],
    digits => [ qw/-a-z.123? 123/ ],
    alphanumeric => [ qw/-a_z.123? az123/ ],
    word => [ qw/-a_z.123? a_z123/ ],
    unix => [ "1\r\n2\r3", "1\n2\n3" ],
    dos => [ "1\r\n2\n3", "1\r\n2\r\n3" ],
    mac => [ "1\r2\n3\r\n4", "1\r2\r3\r4" ],
    no_white => [' no space please ', 'nospaceplease'],
    strip => ['   no leading or trailing space ', 'no leading or trailing space'],
    sql => [qw/you're you''re/],
    escape_html => [qw/<"> &lt;&quot;&gt;/],
    escape_url => [q{some space & ampersands},q{some%20space%20%26%20ampersands}],
    unescape_html => [qw/&lt;&quot;&gt; <">/],
);

SKIP: for my $name (sort keys %map) {
    my $sub = UNIVERSAL::can(__PACKAGE__, $name);
    ok( defined($sub), $name . '() properly exported' ) || skip("$name() isn't defined", 1);
    is(
        $sub->($map{$name}[RAW]),
        $map{$name}[FILTERED],
        $name . '() behaves as expected',
    );
}
