#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 1;

BEGIN: {
	require_ok(qw(IC::View::Base));
}

1;
