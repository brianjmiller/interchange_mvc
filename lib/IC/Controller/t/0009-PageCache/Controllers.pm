package Test::Controllers::Foo;
use IC::Controller;
use base 'IC::Controller';
__PACKAGE__->registered_name('foo');

package Test::Controllers::Bar;
use base 'IC::Controller';
__PACKAGE__->registered_name('bar');

# We need some redundant routes to demonstrate canonical URL retrieval in
# the cache key stuff.
# We want these to be identical except for some simple token in the URL patterns
# that identify the routing class used (for route handler determination)
package Test::Route::One;
use IC::Controller::Route;
use base 'IC::Controller::Route';

sub prefix {
    return 'one';
}

package Test::Route::Two;
use base 'IC::Controller::Route';

sub prefix {
    return 'two';
}

package main;

for my $package (qw( Test::Route::One Test::Route::Two )) {
    $package->route(
        pattern     => $package->prefix() . '/specific',
        controller  => 'foo',
        action      => 'special',
    );
    $package->route(
        pattern     => $package->prefix() . '/:controller/:action',
        defaults    => {
            action  => 'default',
        },
    );
}

1;
