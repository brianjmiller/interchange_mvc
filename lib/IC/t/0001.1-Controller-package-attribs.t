#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use Test::More tests => 11;

my ($class, $ok);
BEGIN {
    $class = 'IC::Controller';
    use_ok($class) && $ok++;
}

BAIL_OUT('Failed to use ' . $class) unless $ok;

=pod

=head1 TEST: CONTROLLER META OBJECT DELEGATION

The purpose of this test is to verify some particulars of the "package attributes"
in IC::Controller, and the underlying meta object IC::Controller::ClassObject.

While the primary IC::Controller test demonstrates that the basics of delegating
"package attributes" from a IC::Controller-derived class to its corresponding
IC::Controller::ClassObject instance, it doesn't address the fact that this
delegation is designed specifically to affect the inheritance chain, such that
the "package attribute" set in IC::Controller-derivative "Foo" is inherited
by "Foo" derivative "Bar".  Plus all the usual things we expect in inheritance
hierarchies; a child can override the parent, a sibling's override doesn't affect
other siblings, etc.

This test should verify all of these things with 9 simple cases that check the
inheritance of package attribute settings across three generations of packages
(grandparent, parent, and child).

=head1 REGARDING MAGIC

Perl has no native construct for package attributes (or class attributes, to
put it in more classical OOPy terms); you can use package variables, of course,
but you use lose the get/set functionality, and they can be directly accessed by
name outside the package.  (Actually, Perl has no native construct for object
attributes, period)

The B<_magical_meta_delegator()> private method of B<IC::Controller> works
in conjunction with B<IC::Controller::ClassObject> such that attributes
of the latter are delegated from the former, such that they appear to be attributes
attached to packages that subclass B<IC::Controller> (not to mention the
B<IC::Controller> package itself).  For this concept of package attribute to
work intuitively, we need the values of these attributes to be inherited by
subclasses just like standard methods are inherited; otherwise, they do not properly
belong at the class/package level.  This is what the B<_magical_meta_delegator()>
method accomplishes.

How does one make object state (since that's what package attributes are) inheritable?

By manipulating the symbol table!  Whenever one of these package attributes is
called as a setter method (meaning with arguments), the _magical_meta_delegator()
installs a new version of the attribute method within the package, which in turn
delegates out to that package's meta object for the attribute value.  Because the
attribute method is installed within the affected package, that method is the version
that will be picked up by derived packages, meaning that we're basically using
Perl method dispatch to implement inheritance (which makes sense, doesn't it?)

You can hopefully see from this explanation why testing the inheritance hierarchy
is necessary.

=cut

# structure the relevant packages that make up our hierarchy
package Top;
use Moose;
extends $class;

package MiddleA;
use base qw(Top);

package MiddleB;
use base qw(Top);

package Bottom;
use base qw(MiddleA);

package main;

# The tests we'll be running:
# - Setting on top inherited by middlea
# - Setting op top inherited by bottom
# - Change in top setting inherited by middlea
# - Change in top setting inherited by bottom
# - Change in middlea setting inherited by bottom
# - Change in middlea doesn't affect middleb
# - Change in middlea doesn't affect top
# - change in middleb setting doesn't affect bottom
# - change in top doesn't affect middlea (overrides still in place)
# - change in top doesn't affect bottom (still inherits from middlea override)

# We'll use the content_type package attribute for our test, since it's simple.
my ($text, $html, $xml) = map { "text/$_" } qw( text html xml );

Top->default_content_type( $xml );
is(
    MiddleA->default_content_type(),
    $xml,
    'Grandparent setting inherited by parent',
);

is(
    Bottom->default_content_type(),
    $xml,
    'Grandparent setting inherited by child',
);

Top->default_content_type( $text );
is(
    MiddleA->default_content_type(),
    $text,
    'Grandparent setting change inherited by parent',
);

is(
    Bottom->default_content_type(),
    $text,
    'Grandparent setting change inherited by child',
);

MiddleA->default_content_type( $html );
is(
    Bottom->default_content_type(),
    $html,
    'Parent setting change inherited by child',
);

cmp_ok(
    MiddleB->default_content_type(),
    'ne',
    $html,
    q{Parent setting change doesn't affect sibling},
);

is(
    Top->default_content_type(),
    $text,
    q{Parent setting change doesn't affect grandparent},
);

MiddleB->default_content_type( $xml );
is(
    Bottom->default_content_type(),
    $html,
    q{Parent sibling setting doesn't affect child},
);

Top->default_content_type( $xml );
is(
    MiddleA->default_content_type(),
    $html,
    q{Grandparent setting change doesn't negate parent override},
);

is(
    Bottom->default_content_type(),
    $html,
    q{Grandparent setting change doesn't affect child inheritance from parent override},
);

=pod

=head1 AUTHOR

Original author: Ethan Rowe (ethan@endpoint.com)

=cut
