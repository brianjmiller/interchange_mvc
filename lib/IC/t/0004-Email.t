#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;

use Test::More tests => 13;

our $class;
BEGIN {
    $class = 'IC::Email';
    use_ok($class);
}

can_ok( $class, 'send' );

my $obj = $class->new;

is_deeply( $obj->addresses, [], 'addresses() default return');
is( $obj->body, undef, 'body() default return');
like( $obj->intercept, qr/\A.+\@.+\z/, 'intercept() default return');
is( $obj->override_intercept, 0, 'override_intercept() default return');

SKIP: {
    skip 'Running in production...', 1 if IC::Config->production;
    like( $obj->subject_prefix, qr/\A\[camp(?:\d+)\]\s\z/, 'subject_prefix() default return (in development)');
    like( $obj->intercept, qr/\A.+\@.+\z/, 'intercept() default return (in development)');
}
SKIP: {
    skip 'Not running in production...', 1 unless IC::Config->production;
    is( $obj->subject_prefix, undef, 'subject_prefix() default return (in production)');
    is( $obj->intercept, undef, 'subject_prefix() default return (in production)');
}

is( $obj->subject, '', 'subject() default return');
is( $obj->bcc, '', 'bcc() default return');
is( $obj->reply_to, '', 'reply_to() default return');
is_deeply( $obj->attachments, [], 'attachments() default return');

__END__
