package IC::Controller::Route;

use strict;
use warnings;

use Moose;
use IC::Controller::Route::Object;
use IC::Controller;

=pod

=head1 NAME

IC::Controller::Route -- Organize route objects and perform mass path lookup/generation operations

=head1 DESCRIPTION

IC::Controller::Route instances contain any number of IC::Controller::Route::Object
instances, and provide an easy interface for adding (and optionally, creating) new
instances thereof; methods provided allow for URL generation and lookups across all
the route objects within the IC::Controller::Route instance.  In this way,
IC::Controller::Route objects organize all the known URL routes within a given
namespace or application.

=head1 USAGE

IC::Controller::Route is really about wrapping multiple routing objects together
into a single namespace.  Though the module is object-oriented in its design, the
common use will be through package-level method calls.  See the section on
PACKAGE SINGLETONS AND SUBCLASSING for details on this.

The details of setting up individual URL routes within a IC::Controller::Route
instance should come from the docs for IC::Controller::Route::Object; instances
of that module make up the routing objects within a given IC::Controller::Route.
This document will not go into the details of routing patterns, defaults, etc.,
only covering how these are used collectively through this module.

  # get an instance.
  my $routes = IC::Controller::Route->new( name => 'some_name' );
  # set up some routes within this instance.  Put most specific routes first,
  # as the first matching route wins when parsing or generating URLs.
  $routes->route(
      pattern     => ':controller/:id',
	  controllers => [qw( products users orders )],
	  action      => 'display',
	  method      => 'get',
  );
  $routes->route(
      pattern     => ':controller/:id',
	  controllers => [qw( products users orders )],
	  action      => 'edit',
	  method      => 'post',
  );
  # for this, don't specify the controllers; in this case, the route will default
  # to work with all controllers publicly named within IC::Controller
  $routes->route(
      pattern     => ':controller/:action/:id', 
	  defaults    => { action => 'index', id => undef, },
  );

The above example registers three different routes within the $routes object.  As the
comment indicates, the order of routes is important; when performing path operations,
the routes are evaluated in order and the first successful route wins.  Consequently,
the more specific the route, the earlier it needs to be added to your IC::Controller::Route
object.

The third route added is the most general of the three; it will match any controller known
to IC::Controller, any action, and will accept a third parameter ('id').  However, the third
parameter is entirely optional, such that it could work with actions that don't technically
use that parameter.  It ensures that the 'index' action is called by default on all controllers.  It works within any HTTP request type.

The earlier two routes both enforce patterns that the third route would match.  However,
they limit those patterns to certain controllers, and they limit further by request type;
the URL 'products/foo' when requested via GET would end up being dispatched to the 'display'
action of the products controller, while the same URL with a POST would go to the 'edit'
action instead.

However, part of this module's intent is to make these collections of routes easily organizable
by package namespace, rather than having to set up actual instances of these objects in global
variables.  While the PACKAGE SINGLETONS AND SUBCLASSING will cover this in greater detail,
note that we could do the following:

  package MyApp::Routes;
  use IC::Controller::Route;
  use base qw(IC::Controller::Route);
  
  __PACKAGE__->route(
      pattern    => 'admin/:resource/:id',
	  controller => 'admin',
	  method     => 'get',
	  action     => 'show',
  );
  __PACKAGE__->route(
      pattern    => 'admin/:resource/:id',
	  controller => 'admin',
	  method     => 'post',
	  action     => 'edit'
  );
  __PACKAGE__->route(
      pattern    => 'admin/:resource/destroy/:id',
	  controller => 'admin',
	  method     => 'post',
	  action     => 'delete',
  );
  __PACKAGE__->route(
      pattern    => ':controller/:action/*params',
	  defaults   => {
	      action => 'index',
	  }
	  method     => 'get',
  );
  ...
  package main;
  # we can perform the routing lookups and whatnot via the package name rather than
  # through an instance
  
  # show me user 124.
  my $params = MyApp::Routes->parse_path( 'admin/users/124' );
  # $params is { controller => 'admin', resource => 'users', id => 124, action => 'show' }...
  
  # now let's edit user 124
  $params = MyApp::Routes->parse_path( 'admin/users/124', 'post' );
  # controller 'admin', resource 'users', id 124, action 'edit'...
  
  # and now for something completely different...
  $params = MyApp::Routes->parse_path( 'television/lessons/topics/seen/not_being' );
  # controller 'television', action 'lessons' params [qw( topics seen not_being )]

This should hopefully illustrate how routes can be used to control the overall flow
of the application, and how they can be used to enforce RESTful design.

=head1 ATTRIBUTES

All attributes are Moose-style, meaning the accessor method is a get/set method.

=over

=item B<name>

The "name" of the instance.  This serves little to no useful purpose at present, except
that for the package singleton objects, the name is set to the name of the package with
which the singleton is associated.

=item B<routes> I<(read-only)>

The list of routes (IC::Controller::Route::Object instances) currently known to
the instance.  This cannot be set directly; it must be manipulated through the
B<route()>, B<add_route()>, and B<clear()> methods.

=item B<controllers>

The list of controllers known to the instance.  Defaults to all the controllers
publicly listed by B<IC::Controller->controller_names>.  All route objects created
through the B<route()> method that do not have explicit controllers listed will use
this attribute for the controller list.

This information is copied, not dynamically fetched, so change this list after
setting up your routes at your peril.

=back

=cut

has name => ( is => 'rw' );
has routes => ( is => 'ro', isa => 'ArrayRef', default => sub { return []; } );
has controllers => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { return [ IC::Controller->controller_names ] },
);

=head1 METHODS

All methods are available as package-level methods as well as object methods; when
called against the package instead of an instance, the package singleton will be
used.

=over

=item B<clear()>

Empties the list of B<routes> known to the object.

=item B<add_route( $route_object )>

Adds $route_object to the B<routes> list.  $route_object must be a IC::Controller::Route::Object
instance.

Returns the size of the B<routes> list as a result.

=item B<route( %route_params )>

Creates a new IC::Controller::Route::Object instance based on the parameters from %route_params
(see IC::Controller::Object::Route for details), and adds that new instance onto the B<routes> list.

Like B<add_route()>, the size of the B<routes> list is returned.

=item B<generate_path( %request_parameters )>

Returns a URL that properly expresses the %request_parameters, based on the routes
known within the B<routes> list; the first route object in B<routes> that can
successfully generate a path for %request_parameters wins, so pay attention to the
order of your route assignments.

If no route can generate a path for the given parameters, this returns undef.

The particulars of %request_parameters are identical to the method of the same name
within IC::Controller::Route::Object.

=item B<parse_path( $path [, $request_type ] )>

Returns a parameter hash based on the data expressed by the $path and optional
$request_type based on the routes within the B<routes> list.  The first object in
B<routes> that can successfully parse the $path (for the optional %request_type)
wins.

If no route in the list can parse the path for the request type, the result is undef.

Like B<generate_path()>, the meaning of the arguments is identical to that of the method
with the same name in IC::Controller::Route::Object.

=item B<instantiate_package_singleton( %constructor_params )>

This creates a new package singleton object for the package through which it is
invoked.  The %constructor_params are passed through to the new object, excluding
the B<name> attribute parameter, which will always be set to the name of the
invocant package.

A reference to the new singleton object is returned.

Typically, it should not be necessary to use this method directly; it is used
automatically whenever the various methods are called with the package as the
invocant, meaning that the package's singleton object is auto-instantiated on demand.

=item B<canonize_path( $path )>

Returns a "canonized" version of $path, basically meaning that the path is cleaned
up such that leading and trailing whitespace and forward slashes are stripped.

This doesn't affect state or anything; it's just a utility method.

=back

=head1 PACKAGE SINGLETONS AND SUBCLASSING

Packages are global.  Therefore, controllers and such known to Interchange are
theoretically known to any and all catalogs within that Interchange daemon.  However,
different catalogs may need their own particular behaviors when it comes to organizing
URLs.  This could be accomplished using different IC::Controller::Route instances,
which would then need to live in a known, global space to be used by the appropriate
catalog(s).  However, this is awkward to set up and not particularly elegant.

Therefore, this module takes advantage of subclassing as a way to facilitate good
organization and ease of use.  Any subclass of IC::Controller::Route can have the
various methods invoked via the subclass package name, and IC::Controller::Route
will ensure that an instance of itself exists specifically for the subclass package.
Thus, the package name itself can effectively be used as an instance of IC::Controller::Route,
except that only the methods are publicly available through the package name (not the
attributes).  Given that all the important manipulation can be done through methods and
through B<instantiate_package_singleton()>, this is not a significant problem.

Refer to the USAGE section for examples on this.  The basic principle is to subclass
IC::Controller::Route and then set up the routes right within your subclass package
definition:

   package Foo::Route;
   use IC::Controller::Route;
   use base qw(IC::Controller::Route);
   __PACKAGE__->route( ... );
   ... and so on.

From there, you can generate paths and parse paths directly through the subclass package:

   Foo::Route->parse_path ( 'some/path' );
   ...
   Foo::Route->generate_path( controller => 'admin', action => 'list', ... );

=cut

sub clear {
	my $self = shift;
	@{ $self->routes } = ();
}

sub route {
	my $self = shift;
	my %options = @_;
	if (! defined $options{controllers}) {
		$options{controllers} = [ @{$self->controllers} ];
	}
	return $self->add_route(
		IC::Controller::Route::Object->new( %options, )
	);
}

sub add_route {
	my ($self, $new_route) = @_;
	push @{ $self->routes }, $new_route;
	return scalar @{ $self->routes };
}

sub parse_path {
    my $self = shift;
	#my ($self, $path) = @_;
	for my $route (@{ $self->routes }) {
		#my $result = $route->parse_path( $path );
		my $result = $route->parse_path( @_ );
		return $result if defined $result;
	}
	return;
}

sub generate_path {
	my $self = shift;
	my %options = @_;
	for my $route (@{ $self->routes }) {
		my $path = $route->generate_path( %options );
		return $path if defined $path;
	}
	return;
}

sub canonize_path {
	my $invocant = shift;
	my $path = shift;
	return $path unless defined $path and length $path;
	$path =~ s!^[\s/]+!!;
	$path =~ s![\s/]+$!!;
	return $path;
}

my %package_singletons;

sub instantiate_package_singleton {
	my $invocant = shift;
	confess 'instantiate_package_singleton() may only be called with a package as invocant'
		if ref $invocant
	;
	my %params = @_;
	$params{name} = $invocant;
	return $package_singletons{$invocant} = $invocant->new( %params );
}

my $package_dispatcher = sub {
	my $code = shift;
	my $invocant = shift;
	return $invocant->$code( @_ )
		if ref $invocant
	;
	my $singleton
		= $package_singletons{$invocant}
			|| $invocant->instantiate_package_singleton
	;
	return $singleton->$code( @_ );
};

around $_ => $package_dispatcher
	for qw(
		clear
		route
		add_route
		parse_path
		generate_path
	)
;

1;

__END__
