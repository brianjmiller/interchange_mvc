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

__END__

=pod

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see: http://www.gnu.org/licenses/ 

=cut
