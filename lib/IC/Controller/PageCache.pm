package IC::Controller::PageCache;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use IC::Controller::HelperBase;

=pod

=head1 NAME

IC::Controller::PageCache

=head1 SYNOPSIS

Provides basic logic for cache key determination, and a general interface for management
of a full-page-cache store.

=head1 DESCRIPTION

B<IC::Controller::PageCache> defines an interface for managing full-page caches
within an MVC application.  It implements logic for determining cache keys based on
the request parameters and the request route handler, with the assumption being that
the canonical (from the route handler's perspective) URL will serve as the cache key
for the request.

The actual storage/retrieval of resources is left to the application engineer to
provide.  That caching mechanism needs to provide the following methods:

=over

=item B<set( %params )>

The B<set()> method will be responsible for storing data into a cache repository.
The method must support the following parameters within I<%params>:

=over

=item I<key>

The cache key identifying the resource within the repository.

=item I<data>

The actual data to be cached.

=back

=item B<get( %params )>

The B<get()> method will be responsible for retrieving data from the cache repository,
and should return undef if the cached resource could not be found.  It must handle the
following parameters within I<%params>:

=over

=item I<key>

The cache key identifying the resource within the repository.

=back

=back

From the perspective of B<IC::Controller::PageCache>, either the cache is there or it isn't;
there's no allowance for locking, cache expirations, etc.; such things are left to the implementation
of the caching mechanism used.

=head1 IMPLEMENTING CACHING MECHANISMS

Any caching mechanism to be used within B<IC::Controller::PageCache> need only implement the
interface described above (B<get()> and B<set()> methods and their appropriate parameters).  The
B<IC::Controller::PageCache> methods do not make a distinction between blessed references (objects)
or package names when caching mechanisms are specified, so caching mechanisms can take either form.

The public methods of B<IC::Controller::PageCache> allow for explicit specification of the
cache mechanism (see their documentation for details), meaning the cache mechanism can be passed
in by the caller.  When not provided in this manner, these functions look for get/set methods on
their invocant; therefore, another way to implement a cache mechanism is to subclass
B<IC::Controller::PageCache> and provide implementations for get/set in your subclass.  The
latter approach is how B<IC::Controller> expects the implementation to work.

=head1 METHODS

=over

=item B<determine_cache_key( %args )>

As the name suggests, determines the cache key appropriate for the request determined by
the parameters and the route handler provided, and returns that key.

Expects to find in I<%args>:

=over

=item I<route_handler>

A route handler module name or object reference; the route_handler will be used to find the
canonical URL for the given request parameters, which serves as the cache key.

If the route_handler is not specified, the route_handler of the current controller bound to
B<IC::Controller::HelperBase> will be used.  If no such route handler exists, an exception
will be thrown.

=item I<parameters>

The URL parameters representing the request the cache key of which is to be determined.
This must be a hashref (though an empty hashref is arguably acceptable, if your route handler
can provide a URL for no parameters), and it is expected to contain the name of the
controller to use under the hash key 'controller'.

If 'controller' is not specified therein, the current bound controller name will be used
as the controller of choice.

=back

=cut

sub determine_cache_key {
    my $self = shift;
    my %opt = @_;
    my $routes = $self->resolve_routes( $opt{route_handler} );
    my $params = $opt{parameters} || {};
    die "The 'parameters' argument must be a hashref!\n"
        unless ref $params eq 'HASH'
    ;
    my $controller = $self->resolve_controller( $params->{controller} );
    # More need for exception objects
    die "No route information provided for cache key determination!\n"
        unless defined $routes
    ;
    die "No controller specified for cache key determination!\n"
        unless defined $controller
    ;
    
    %opt = %$params;
    $opt{controller}
        = UNIVERSAL::can($controller, 'registered_name')
            ? $controller->registered_name
            : $controller
    ;
    return $routes->generate_path( %opt );
}

=item B<get_cache( %params )>

Checks the cache repository (via the cache handler mechanism) for a cache
matching the current MVC request and returns that cached data if it exists;
undef is returned if no such data is found.  If no appropriate cache
handler is found for the actual underlying implementation of the caching
system, an exception is thrown.

Expects parameters in I<%params>:

=over

=item I<parameters>

The request parameters, controller, etc. for the request cache to check.  See
B<determine_cache_keys()> for how this is treated.

=item I<route_handler (optional)>

The package/object that provides route handling for cache key determination.
See B<determine_cache_keys()> for how this is treated.

=item I<cache_handler (optional)>

The package name or object reference for the cache mechanism to use; the
cache_handler specified must provide get/set methods as described above.

If cache_handler is not provided, will use the invocant against which
I<get_cache()> was invoked as the cache_handler.

=back

=cut

sub get_cache {
    my $self = shift;
    my %opt = @_;
    my $cache = $self->resolve_cache_handler( delete $opt{cache_handler} );
    
    my $cache_sub = $cache->can('get');
    unless ($cache_sub) {
        my $class = blessed($cache) || $cache;
        die "Cache class '$class' has no get() method for caching retrieval!\n";
    }

    my $key = $self->determine_cache_key( %opt );
    return if ! defined $key;
    
    return $cache->$cache_sub(
        key => $key,
    );
}

=item B<set_cache( %params )>

Stores within the cache handler the data provided at the appropriate
cache key location based on the canonical URL.  If no appropriate cache
handler is found for the underlying implementation of the cache mechanism,
an exception is thrown.

The I<%params> hash is expected to provide:

=over

=item I<data>

The actual data to store (typically, HTML text content).

=item I<parameters>, I<route_handler>, I<cache_handler>

See B<get_cache()>'s treatment of these options.

=back

=back

=cut

sub set_cache {
    my $self = shift;
    my %opt = @_;
    my $cache = $self->resolve_cache_handler( delete $opt{cache_handler} );

    my $cache_sub = $cache->can('set');
    unless ($cache_sub) {
        my $class = blessed($cache) || $cache;
        die "Cache class '$class' has no set() method for cache storage!\n";
    }

    my $key = $self->determine_cache_key( %opt );
    return if ! defined $key;
    
    return $cache->set(
        key     => $key,
        data    => delete $opt{data},
    );
}

sub resolve_routes {
    my ($self, $route) = @_;
    if (!defined($route)) {
        my $c = IC::Controller::HelperBase->controller;
        $route = $c->route_handler;
    }
    return $route;
}

sub resolve_controller {
    my ($self, $c) = @_;
    return $c || IC::Controller::HelperBase->controller;
}

sub resolve_cache_handler {
    my ($self, $handler) = @_;
    return $handler if defined $handler;
    return $self;
}

1;

__END__

=head1 AUTHOR

Ethan Rowe

End Point Corporation

ethan@endpoint.com

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
