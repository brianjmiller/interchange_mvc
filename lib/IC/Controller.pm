package IC::Controller;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use IC::Log::Logger::Moose;
use IC::View;
use IC::Controller::ClassObject;
use IC::Controller::Request;
use IC::Controller::Response;
use IC::Controller::HelperBase ();
use IC::Controller::Route::Helper ();
use IC::Controller::RenderHelper ();
use IC::Controller::FilterHelper ();
use Exception::Class (
    __PACKAGE__ . '::Exception::Request' => {
        description => 'Exceptions related to high-level request processing',
        fields => [qw(
            action
            cgi
            controller
            headers
            path
            path_params
            request_class
            route_handler
        )],
    },
);

extends 'IC::Log::Logger::Moose';

my $view_class = 'IC::View';
my $response_class = __PACKAGE__ . '::Response';

=pod

=head1 NAME

IC::Controller

=head1 DESCRIPTION

Base class for application controllers in the MVC subsystem, along with package-level methods for
registering controllers with simple names, instantiating controllers by name, etc.

=head1 ATTRIBUTES

All attributes are Moose-style, meaning they each are accessed using a get/set accessor method.

The attributes are additionally magical in that all the attributes of a IC::Controller instance
(or subclass instance) are automatically exported into the view's context as usable data for the
rendering of "layouts".  This is not currently the case for the rendering of the action view portion
of a render call, though this is potentially subject to change.

=over

=item B<parameters>

Returns a hashref of parameters appropriate to the current request; these parameters are higher-level than
the classic Interchange CGI-space parameters, as they combine GET/POST variables (using only the variables
submitted appropriately for the request method type, for RESTful behavior) with any parameters extracted
from the request URL during routing (see B<IC::Controller::Route> for more information on routing).

Assuming the Interchange daemon configuration is consistent with any expectations outlined for the
B<IC::Controller::Route> module, the B<parameters> hash will receive GET variables if the request is a GET
request, POST variables if the request is a POST request, and URL parameters from routing regardless of
request method.  Furthermore, the parameters will be transformed from flat "variables" (key/value pairs)
to nested data structures according to naming conventions similar to that of the Rails framework:

=over

=item *

Simple key values like 'foo', 'some_field', etc. appear unmolested in the B<parameters> hash.

=item *

Any value in the parameter list containing null characters will be transformed into an arrayref by splitting
on the null character; this is idiomatic to Interchange, which takes multiple values submitted in GET/POST
with the same name and turns them into a single scalar in %CGI::values, separated by nulls.

=item *

Keys that end with a single set of empty brackets, '[]', will be transformed into an arrayref regardless of
the existence of values, this catches the case where an intentional list like parameter only gets a single
value (aka no null strings will be found, see above) which prevents the need to check for references in user
code.

=item *

Keys that end with arbitrary sets of '[I<some_name>]' sequences will appear as nested hashes within the
B<parameters> hash.  For instance:

  'person[name]' => 'Charles Mingus'

would appear in B<parameters> as

  person => { name => 'Charles Mingus', }

This can go arbitrarily deep:

  'person[musical_traits][composition][skill_level]' => 'r0x0rs!'

transforms to;

  person => {
      musical_traits => {
          composition => {
              skill_level => 'r0x0rs!',
          },
      },
  }

=item *

At present, no additional allowances are made for array transformations based on the naming scheme.
Given the Interchange null-separated list approach mentioned above, it may not be necessary to take
any additional action for arrays.

=back

The settor behavior of this attribute is magical in that it scans the hashref provided as the new value and
performs the transforms described above to ensure that the hashref stored within B<parameters> always meets
the expectations of the consumer.  It is theoretically possible to override this in a subclass, but that would
be a Bad Idea, as it would be modifying a critical portion of the interface.

=item B<request>

Get/set the "request" object for representation of the current request.  This object is expected to be
an instance of B<IC::Controller::Request> (or implementor of its interface).  In a typical request process,
the B<request> attribute will already be populated, and implementors of specific controllers (i.e. subclasses
of B<IC::Controller> specific to the application) can simply rely on that object's availability to inspect
the cookies, the request type, SSL information, etc.  While this attribute allows explicit setting of this
object, use of the attribute as a settor is strongly discouraged.

=item B<response>

Get/set the "response" object for representation of the response currently under construction for the active
request.  The "response" object is expected to be an instance of B<IC::Controller::Response> (or an implementor
of its interface).

The "response" object is auto-instantiated by B<IC::Controller>, and is wide open to use by consumers of this
module.  However, generally speaking, it makes sense to minimize use of the response object directly, excluding things
like adjusting the response headers (via $self->response->headers).  Direct manipulation of the response buffer(s)
is strongly discouraged; let the B<IC::Controller> object take care of that for you.

=item B<scratch>

Get/set the hashref representing "scratch space" in classic Interchange ITL.  Scratch space is entirely idiomatic
to ITL and to Interchange magical processes, both of which present the very problems that this MVC subsystem attempts
to remedy.  Consequently, while this attribute is available to allow interaction between the MVC subsystem and classic
ITL-oriented constructs, there's absolutely no reason to use scratch space in pure MVC work and plenty of reasons not
to use it.  So don't use it unless you have no choice.

=item B<session>

Get/set the hashref representing the current session.  This will be automatically set up by the dispatching system,
so using it as a settor is discouraged.  Use this as an accessor to work with the session within your controller code.

=item B<values>

Get/set the hashref representing "values space" in classic Interchange ITL.  Please see the advisory comments for
B<scratch>, but add the words "more so" in this case.  Values space is arguably even more tightly bound to magical
Interchange behaviors and ITL idiosyncracies than is scratch space.  The same design concerns apply.

=item B<view>

The instance of B<IC::View> used by the controller instance for rendering functions; this can be set directly,
but doing so is entirely unnecessary.  Furthermore, while attributes on the underlying view object may be changed,
the B<view_path> and B<view_default_extension> attributes of the controller will always be enforced when the view
is used by the controller's rendering logic (B<render()> and B<render_local()>).

=item B<view_path>

The base path to use for the controller's B<view> object.  All template files (views/layouts) are expected to be
relative to this path.

=item B<view_default_extension>

The default filename extension to assume on template files (views/layouts) when rendering.  Corresponds to the
underlying view object's B<default_extension> attribute.

=item B<route_handler>

The object or package name used for routing the current request to the current controller.  This is important if
chaining requests is desired, as it can be passed along subsequent calls to ensure consistent routing.

Like the I<route_handler> parameter of B<process_request()>, B<route_handler> does not need to be an object; it
simply needs to be an invocant (either by reference or by package name) that implements the interface defined
by B<IC::Controller::Route> (specifically, the B<parse_path()> and B<canonize_path()> methods).

=item B<content_type>

The content type header to send by default for B<render()> and B<redirect()>.  If set to a Perly-false value,
or not set at all, the B<default_content_type()> package attribute will be used to determine this.

=item B<page_cache_handler>

The page cache handler (see B<IC::Controller::PageCache> for more information regarding
what constitutes a page cache handler) to use for page caching operations.  If not set
and page caching is applicable to the controller (see the B<cache_pages> package attribute),
the B<default_page_cache_handler> package attribute is used.

=item B<get_logger()>, B<set_logger( $log_obj )>, B<has_logger()>

Get set, and predicate check (respectively) the logger object to be used by the controller instance.  This
affects the result of the I<logger()> method, and is part of the "I can log" behavior
described in B<IC::Log::Logger>.

This particular attribute and its accessors come from B<IC::Log::Logger::Moose>; refer
there for details.

=back

=cut

has session => ( is => 'rw', );
has request => ( is => 'rw', );
has response => ( is => 'rw', default => sub { return $response_class->new; }, );
has parameters => ( is => 'rw', isa => 'HashRef', );
has scratch => ( is => 'rw', isa => 'HashRef', );
has 'values' => ( is => 'rw', isa => 'HashRef', );
has view_path => (
	is		=> 'rw',
	default	=> sub {
		return 'views';
	},
);
has view => (
	is		=> 'rw',
	isa		=> $view_class,
	default	=> sub {
		return $view_class->new();
	},
);
has view_default_extension => ( is => 'rw', );
has route_handler => ( is => 'rw', );
has content_type => ( is => 'rw', );
has page_cache_handler => ( is => 'rw', isa => 'CacheHandler' );

{
    my %class_objects;
    sub class_object {
        my $invocant = shift;
        my ($package, $metaclass, $metaobj);
        $package = ref($invocant) || $invocant;
        $metaclass = __PACKAGE__ . '::ClassObject';
        if (@_) {
            $metaobj = shift;
            confess "The class_object may only be set when called against the package, not an instance!\n"
                if $invocant ne $package
            ;
            confess "The class_object may only be set to a derivative of $metaclass!\n"
                unless $metaobj->isa($metaclass)
            ;
            $class_objects{$package} = $metaobj;
        }
        unless ($metaobj ||= $class_objects{$package}) {
            $class_objects{$package} = $metaobj = $metaclass->new( package => $package );
        }
        return $metaobj;
    }
}

sub default_content_type {
    return  __PACKAGE__->_magical_meta_delegator( 'default_content_type', 'content_type', @_ );
}

__PACKAGE__->default_content_type( 'text/html' );

sub default_helper_modules {
    return __PACKAGE__->_magical_meta_delegator( 'default_helper_modules', 'helper_modules', @_ );
}

__PACKAGE__->default_helper_modules([qw(
    IC::Controller::Route::Helper
    IC::Controller::RenderHelper
    IC::Controller::FilterHelper
)]);

sub default_page_cache_handler {
    return __PACKAGE__->_magical_meta_delegator( 'default_page_cache_handler', 'page_cache_handler', @_ );
}

sub cache_pages {
    return __PACKAGE__->_magical_meta_delegator( 'cache_pages', 'cache_pages', @_ );
}

sub page_cache_no_reads {
    return __PACKAGE__->_magical_meta_delegator( 'page_cache_no_reads', 'page_cache_no_reads', @_ );
}

sub error_handler {
    return __PACKAGE__->_magical_meta_delegator( 'error_handler', 'error_handler', @_ );
}

sub _magical_meta_delegator {
    my $bound_package = shift;
    my $local_sub = shift;
    my $attr_name = shift;
    my $invocant = shift;
    if (@_) {
        $bound_package = blessed($invocant) || $invocant;
        if (! $bound_package->meta->has_method( $local_sub )) {
            $bound_package->meta->add_method(
                $local_sub,
                sub {
                    return $bound_package->_magical_meta_delegator(
                        $local_sub, $attr_name, @_
                    );
                },
            );
        }
        my $sub = $bound_package->class_object->can( $attr_name );
        return $bound_package->class_object->$sub( @_ );
    }
    my $sub = $bound_package->class_object->can( $attr_name );
    return $bound_package->class_object->$sub();
}

=pod

=head1 METHODS

=over

=item B<render_local( %option_list )>

Calls out to the view rendering subsystem to render a particular view (and optional layout), with an arbitrary
set of data to marshal into the view's context.  The details of that marshalling are entirely dependent on the
view engine used for the view requested (which is determined by the view file's extension and the available
view plugins set up with B<IC::View::Base>).

The rendered content is returned as a string to the caller.

A B<render_local()> call requires a view, which is expected to be a filename relative to B<view_path>.  If no view
can be found for rendering, an exception is thrown.  Furthermore, a I<layout> may also be specified; when a layout
is provided, a second rendering process occurs, with the content resulting from rendering the view being made available
within the layout's context.  In this way, hierarchies of templating can be achieved, in that the view is the more
specific template, and its resulting content is injected into a more general template (the layout).  In addition to
the view's content being made available to the layout, all attributes of the controller are marshalled to the layout
as well; consequently, arbitrary content can be stored in controller attributes and then used within the layout to
piece together a rendered whole.

In any call to B<render_local()>, the I<%option_list> may contain:

=over

=item I<view> => I<view_name|view_list_ref>

The I<view> tells B<render_local()> the primary template to use for the rendering.  It may take the form of a simple
scalar name, or it can be an arrayref of names; when an arrayref is provided, the first list member found within the
file system will be used.

The I<view> is a required parameter; if no view is specified, or if the view specified cannot be found, an exception
occurs.

The I<view> value(s) should be relative to the controller's B<view_path>.

=item I<layout> => I<layout_name|layout_list_ref>

The optional I<layout> argument tells B<render_layout()> to use the specified layout in the manner described above.
The I<layout> argument, like I<view>, may be a single filename or an arrayref of filenames, the first of which found
in the filesystem would be used.

The I<layout> value(s) should be relative to the controller's B<view_path>.

The controller's attributes are marshalled by name into the layout's context when rendering.  The content resulting
from the rendering of I<view> is marshalled as well, with the name I<action_content>.  The view's rendered content
will override any controller attribute of the same name when marshalling.

=item I<context> => I<data_hashref>

The name/value pairs provided via hashref to I<context> determine the information marshalled into the view's context.  If
unspecified, then no data is made available to your view.

Note that I<context> is not used for determining the marshalling to I<layout>.

=back

Note that both I<view> and I<layout> go through B<IC::View>, and as such use entirely independent rendering operations;
they can use different view types entirely and have no relation other than the result of the I<view> being marshalled into
the context for I<layout>.  Furthermore, note that the controller package's
B<default_helper_modules> method is invoked at this time to determine the list of
helper modules that should be made available (as possible, as implemented by the view
engines themselves) to the views.  Therefore, to extend the list of helper modules made
available to your views, override the B<default_helper_modules> method within your
subclass(es).

=item B<render( %option_list )>

The B<render()> method is conceptually identical to B<render_local()>, and takes precisely the same arguments.
However, there are a few differences in the behavior and the defaults.  While B<render_local()> is for the
purposes of rendering to strings, B<render()> is the means by which content is ultimately organized for return
to the client.

The critical differences:

=over

=item *

The I<layout> argument, if not present in I<%option_list>, defaults to 'layouts/I<registered_name>', where
I<registered_name> is the value of the controller package's B<registered_name>.  If the controller package
has no such name, no default layout is used.  The default layout will only apply if the default layout name
actually corresponds to an existing view file; reliance on the default layout will not result in an error
condition in the event that no such layout file exists.  Specifying a nonexistent layout, however, will generate
an error condition, even if the layout specified is the same as the default.  The default layout can be
"turned off" by providing a I<layout> value of I<undef>.

=item *

The I<view> argument, if not present in I<%option_list>, defaults to 'I<registered_name>/I<action>', where
I<registered_name> is the B<registered_name> of the controller's package, and I<action> is the name of the
action currently held in the B<parameters> hash (presumably corresponding to the action currently underway.
If the controller has no registered name, then no view default is used.

=item *

The content resulting from B<render()> goes into the B<buffer> of the controller's B<response>.  It is not
returned by B<render()>.  Given that the B<response> is the means by which the controller's work is communicated
back to the client, B<render()> is the appropriate way to prepare content as the ultimate result of the current
process.

=back

Since the B<render()> method puts its content into the B<response> buffer, a B<render()> may only occur once
per process.  Attempting multiple B<render()> calls in a single controller process will result in an error.  If
multiple renderings are necessary, use B<render_local()> to render the subsections into controller attributes,
and then use a final B<render()> call (preferably with a layout) to pull all the pieces together.

=item B<url( %params )>

A method for generating full URLs to MVC resources, standard Interchange pages, and
external resources.  This is largely a wrapper for the B<url()> method of the
B<IC::Controller::Route::Helper> module, and the inputs it expects are the same.
The only difference is the default behavior regarding the I<controller> parameter;
if there is no known bound controller handling the current request, then the controller
instance on which the method was invoked is used as the fallback controller name.  Its
route handler will also be used for the routing portion of URL generation.

=item B<logger()>

Returns an object for logging; see B<IC::Log::Logger::Moose> for details, but generally
speaking this will return either what your instance has set via I<set_logger> (see the
ATTRIBUTES section) or will default to a system-wide default logging object determined by
B<IC::Log>.

In short, do "$self->logger->debug(...)" to issue debug messages, etc.

=back

=head1 PACKAGE-LEVEL METHODS

These methods can only be invoked against an actual package (i.e. __PACKAGE__->foo()) rather than object
instances; in each case, an exception will be thrown if invoked as an object method instead.

=over

=item B<registered_name( [ $simple_name ] )>

Get/set the simple name for the controller subclass package on which it is invoked.  If called with no arguments,
simply returns the simple name for the invocant package (if one exists; otherwise, undef is returned).  If called
with $simple_name, the invocant package is registered as having $simple_name for its name (which will subsequently
show up in calls to B<controller_names()> and B<get_by_name()>), replacing any previous name that may have been
registered already.  If called with I<undef> as the value for B<$simple_name>, the invocant package's registered
name is cleared, effectively removing the controller from the standard request dispatching process.

=item B<controller_names()>

Returns a sorted list of known controller names.

=item B<get_by_name( $name [, %constructor_options ])>

Looks up the controller package by B<$name> (meaning the controller package registered with B<$name> via B<registered_name()>)
and returns a new instance of that controller, passing through any other arguments to the constructor call.

=item B<process_request( %options_list )>

Where all the magic happens.  The B<process_request()> method does exactly what it suggests: it processes a request, from top
to bottom.  The path requested goes through the B<IC::Controller::Route> subsystem to determine the relevant controller
and action, and from there, the controller is initialized using B<process_initialization>, instantiated, parameters prepared,
etc., and the action requested invoked.  The return value of B<process_request()> will be undef if the routing determines
that the path cannot be processed, or will be the controller instance's B<IC::Controller::Response> object if the request
was handled.

The options needed within the name/value pair I<%options_list>:

=over

=item I<path>

The URL fragment to process.  Required.

=item I<cgi>

A reference to the hash containing the GET/POST variables for the current request.  Not technically
required, but really rather necessary.

=item I<headers>

A reference to the hash containing the various Interchange-stylized HTTP headers.  Like I<cgi>, this
isn't strictly required, but is rather important.

=item I<request_class>

Optional; the package name to use for the request object within the controller.  Defaults to 'IC::Controller::Request'.

=item I<route_handler>

Optional; either a blessed reference or a package name for an object/package that is capable of performing the routing
function (for determining how to dispatch the request within the MVC framework).  This would typically be the name of
a subclass of B<IC::Controller::Route>, or an instance thereof.  The type isn't checked, but the value provided needs
to provide the B<parse_path()> method as outlined for B<IC::Controller::Route>.

=back

Any other name/value pairs provided in I<%options_list> will be passed to the constructor call for the controller object
instantiated for the actual request logic; therefore, things like the controller's B<view_path>, B<view_default_extension>,
and so on may be specified through I<%options_list>.  This is the only way the controller instantiated within method can
be directly affected, so use of this ability is recommended, particularly since view paths and such can be critical to
control when running multiple catalogs out of a single Interchange daemon.

=item B<process_intialization>

Controller-specific method to perform any class-specific initialization for the B<process_request> method; the default
behavior is a no-op.  Called internally from B<process_request>, there should be no need to call this method directly.

=item B<caches_page( $action_name )>

Returns a Perly true/false indicating whether or not page caching applies to the
action specified by I<$action_name>, determined by the B<cache_pages> package-level
attribute.

=item B<set_page_cache( $path_params_hashref )>

Given the URL path parameters (as determined by the B<route_handler>, prior to merging
in GET/POST parameters) that correspond to the current action/resource, sets the page
cache for the current action, based on the contents of the instance's
B<IC::Controller::Response> object's buffer.

The cache will only be set if the request method is GET and the buffer is actually
defined (meaning it has been set; it is valid for the buffer to contain the empty
string, however).

While this can be invoked directly if desired, there's arguably little reason to do
so, as it is built into the B<process_request()> method.

If no cache is set, this returns undef.  If the cache does get set, it returns whatever
the page cache handler returns when setting a cache entry.

=item B<check_page_cache( $path_params_hashref )>

Given URL path parameters (again, as they would be determined by the B<route_handler>),
checks to see if a page cache exists for the resource identified by those parameters;
if the resource exists, the controller's response object will be set to hold the cache's
data in the buffer, along with the appropriate content type as determined by the content
type set on the instance or in the class' B<default_content_type> attribute, returning
a reference to the response object.  If the cache doesn't exist, returns undef.

The behavior of this method is further affected by the B<page_cache_no_read> package
attribute; if that attribute is I<true>, then B<check_page_cache()> will never
read from the page cache.

This is possibly more useful for direct use than the sibling B<set_page_cache()> method,
but this method is also used within B<process_request()> and would not typically need
to be used directly.

=item B<get_logger_default()>

Inherited from B<IC::Log::Logger::Moose>, this specifies the default logging construct
to use with the I<logger()> method.  Override this method in your subclass(es) if you
want to use a default other than B<IC::Log> (which should not typically be necessary).

=back

=head1 PACKAGE-LEVEL ATTRIBUTES

B<IC::Controller> allows the setting of various attributes at the package level,
meaning that the attribute applies for the package as a whole; package-level
attribute values are inherited by subclasses.  These attributes are Moose-based,
meaning they can be used for get/set operations, though changing package-level
attribute values at runtime is not typically recommended.

The package-level attributes rely on delegation to the underlying meta object
returned by the B<class_object> package method, meaning that actual attributes
are defined in B<IC::Controller::ClassObject> instances.

When subclassing B<IC::Controller>, simply use these attributes as setters within
the subclass definition itself, like so:

 package Controller::Foo;
 use base qw(IC::Controller);
 __PACKAGE__->default_page_cache_handler( 'Some::Cache::Handler::Package' );
 ...

=over

=item B<cache_pages>

Registers action names for which page caching should be applied.  The list of
names may be provided in one of two ways:

=over

=item *

As a hashref, with each action to be cached specified as a key with a correspond
Perly-true value

=item *

As an arrayref, merely listing the action names to be cached.

=back

The attribute will return the hashref form, but is designed for ease of use,
meaning arrayrefs are the intended means of setting the attribute.

=item B<default_content_type>

The default content-type HTTP header to use for B<IC::Controller::Response> when
rendering within the given controller class.

The ultimate default (set in B<IC::Controller>) is to use 'text/html'.

=item B<default_helper_modules>

An arrayref specifying the package names of modules that should be imported into
any supporting view languages (see B<IC::View> for details).  It probably doesn't
make sense to replace the defaults provided by B<IC::Controller> outright, but rather
to supplement them as needed.

The defaults are:

=over

=item B<IC::Controller::Route::Helper>

=item B<IC::Controller::RenderHelper>

=item B<IC::Controller::FilterHelper>

=back

See B<IC::Controller::HelperBase> for details about how helper modules work and
their interface requirements.

=item B<default_page_cache_handler>

The page cache handler to use by default for all instances of the class for any page
caching operations.  See the section on page caching for more information.

=item B<error_handler>

A method subroutine reference or a method name to invoke when an exception is
thrown within B<process_request()>.  This provides high-level error handling support
within the main MVC dispatch process.

See the B<ERROR HANDLING> section for more details.

=item B<page_cache_no_reads>

A boolean attribute; when set to true, the page caching portion of the request
process will not read from the page cache; however, writes to the page cache
will continue to take place.  This kind of setting would be appropriate in
situations where your web server is responsible for serving directly from the
page cache, meaning that the app server shouldn't ever receive requests if the
cache exists.

Defaults to I<false>.

=back

=head1 ERROR HANDLING

Within the B<process_request()> method, any unhandled exception that percolates up,
or any exception thrown by the method itself, will be dispatched to the B<error_handler>
specified.  The return value of that error handler method will be the return value
of B<process_request()> in this case.  Therefore, your error handler routines should
typically return a properly-prepared IC::Controller::Response object.

One point of potential confusion regarding B<error_handler>: the controller package
whose B<error_handler> is invoked depends on where in B<process_request()> the
exception occurs; this is because B<process_request()> may be invoked on one particular
package, but the controller used to handle the request may be an instance of an entirely
different package.  Therefore, during early portions of B<process_request()> (when
the path is being evaluated by the B<route_handler>), exceptions will be handled by
the B<error_handler> of the package on which B<process_request()> was invoked.  Once
a controller has been identified for the requested path, however, any subsequent exceptions
will be handled by the B<error_handler> of that controller.

The B<error_handler> specified for a given controller should be designed as a method sub
(even when provided as a subref rather than a method name), meaning that it expects to receive
the invocant package/object as the first argument.  The second argument is an instance
of B<IC::Controller::Exception::Request>, which has the following attribute methods:

=over

=item B<error>

Returns the exception that was handled; this may be a raw error string or an exception
object; it depends on the exception.

=item B<action>

Returns the name of the action determined from the path/route_handler.

=item B<cgi>

Returns the hash of HTTP variables provided to B<process_request()>.

=item B<controller>

Returns the controller instance used for handling the appropriate action.

=item B<headers>

Returns the headers hash provided to B<process_request()>.

=item B<path>

Returns the path provided to B<process_request()>.

=item B<path_params>

Returns the path parameters hash determined by the route_handler based on the path.
This will be the path_parameters prior to merging with the B<cgi> hash, meaning that it
is not the same hash as the one found at controller->parameters.

=item B<request_class>

The package name of the class used for the request object.

=item B<route_handler>

The package/object used for handling the routing.

=back

Note that the only things you can absolutely rely upon being defined are the error itself,
the path, and the route handler.  All others may or may not be set depending on where
in B<process_request()> the exception occurs.

=head1 PAGE CACHING

B<IC::Controller> offers built-in support for full page caching, provided a cache
mechanism is specified for the actual caching layer.  The page cache interface is
intentionally simple and straightforward, so integrating caching mechanisms is as
easy and painless as possible.

See B<IC::Controller::PageCache> for details about integrating a cache mechanism
into the page caching system; it defines the necessary interface that must be implemented
by the caching mechanism in order to function as a page cache handler.

The page cache handler for a given controller instance is determined by:

=over

=item *

Checking the instance's B<page_cache_handler> attribute, which is used if set.

=item *

Checking the package-level B<default_page_cache_handler> attribute, used as the
fallback.

=back

Attempts to cache pages will fail if no page cache handler is specified, or if the
handler specified does not implement the interface properly.

Page caching is done on an action-by-action basis.  The controller package's
B<cache_pages> attribute determines the actions subject to page caching.  Page caching
should only be used on requests that cannot modify state, which means that only GET
requests are considered for caching.  This means that applications will fit into the
caching system more effectively if they make use of RESTful design principles; the
GET version of a particular URL can safely be cached, while the POST version won't,
which could fit into certain application needs quite well.

The page caching system determines the cache key that uniquely identifies a given
resource to cache based on the path parameters determined by the current route handler.
The path that is determined to be canonical for the given resource by the route handler
will be used as the cache key.  The result is that URLs that map to the same resource
will all share the same page cache.  Furthermore, if the cache handler can be made to
store caches using the cache key as a literal relative path, placing the cache in
plaintext somewhere within the docroot, the web server may potentially serve the
cached pages directly (assuming a proper set of rules within the webserver for performing
this duty), bringing an excellent scalability improvement.

Since only the URL parameters determined by the route handler are used for creating the
cache key for a given action, GET parameters are ignored.  Consequently, actions that
use page caching must be carefully designed to use URL parameters only; any GET parameters
on which such actions depend will break, as they are invisible to the caching system.  Again,
this merely encourages RESTful design and more rigorous organization of routes.  If an
action uses GET variables and is set to use page caching, the cache of the action will
always reflect the combination of path and GET parameters as they were when the cache was
first created, regardless of subsequent GET parameters with those corresponding path
parameters.

If this is confusing, then a review of B<IC::Controller::Route> may help.

=cut

my %controller_registry;
my %name_registry;

sub registered_name {
	my $invocant = shift;

	my $class = ref($invocant) || $invocant;
	return $controller_registry{$class}
		unless @_
	;

	confess 'registered_name() only available as settor for packages!'
		if ref $invocant
	;

	my $new_name = shift;

	# an undef results in clearing the registration for the package.
	if (! defined $new_name) {
		delete $name_registry{ delete $controller_registry{ $class } };
		return;
	}

	confess(
		sprintf
			'The requested name "%s" is already registered to package %s',
			$new_name,
			$name_registry{$new_name},
	) if $name_registry{$new_name}
        and $name_registry{$new_name} ne $class
    ;

	if (my $old_name = $controller_registry{$class}) {
		#warn(
			#sprintf
				#'Redefining name registration of controller package %s from "%s" to "%s"',
				#$invocant,
				#$controller_registry{$class},
				#$new_name,
		#);
		delete $name_registry{$old_name};
	}

	$name_registry{$new_name} = $class;
	return $controller_registry{$class} = $new_name;
}

sub controller_names {
	my $invocant = shift;
	confess 'controller_names() only available as a class method'
		if ref $invocant
	;

	return sort {$a cmp $b} keys %name_registry;
}

sub get_by_name {
	my $invocant = shift;
	confess 'get_by_name() only available as a class method'
		if ref $invocant
	;

	my $name = shift;
	confess 'get_by_name() requires a name parameter'
		unless $name
	;

	my $class = $name_registry{$name};
	confess 'get_by_name(): unknown controller name: ' . $name
		unless $class
	;

	return $class->new( @_ );
}

my $validate_view_parameter = sub {
	my $self = shift;
	my $view = shift;
	return unless defined $view
		and (
			ref($view) eq 'ARRAY' && @$view
			or $view =~ /\S/
		)
	;
	return $view;
};

my $prepare_context_from_attributes = sub {
	my $self = shift;
	my %context;
	for my $attrib ($self->meta->compute_all_applicable_attributes) {
		my $name = $attrib->name;
		my $accessor = $self->can( $name );
		$context{ $name } = $self->$accessor;
	}
	return \%context;
};

my $render_layout = sub {
	my $self = shift;
	my ($layout, $content) = @_;
	my $context = $self->$prepare_context_from_attributes;
	$context->{action_content} = $$content;
	my $rendered_content = $self->view->render( $layout, $context );
	return \$rendered_content;
};

my $initialize_view = sub {
	my $self = shift;

	unshift @{ $self->view->base_paths }, $self->view_path;
	$self->view->default_extension( $self->view_default_extension )
		if defined $self->view_default_extension
	;
    $self->view->helper_modules( [ $self->default_helper_modules ] );

	return;
};

my $render_internal = sub {
	my $self = shift;
	my %params = @_;
	my $context = delete($params{context}) || {};
	# This ought to be an exception object...
	confess 'render_internal() context must be a hashref!'
		unless ref $context eq 'HASH'
	;
	my $view = $self->$validate_view_parameter( delete $params{view} );
	# This also deserves an exception object...
	confess 'render_internal() requires a view!'
		unless defined $view
	;
	my $layout = $self->$validate_view_parameter( delete $params{layout} );

	$self->$initialize_view();
	my $content = $self->view->render( $view, $context );
	return \$content unless defined $layout;
	return $self->$render_layout( $layout, \$content );
};

sub render_local {
	my $self = shift;
	my $result = $self->$render_internal( @_ );
	return $$result if defined $result;
	return;
}

my $determine_default_layout = sub {
	my $self = shift;
	my $params = shift;
	return if exists $params->{layout};
	return if ! defined $self->registered_name();

	$self->$initialize_view();
	my $layout = 'layouts/' . $self->registered_name();
	$params->{layout} = $layout
		if defined $self->view->identify_file( $layout )
	;
	return;
};

sub render {
	my $self = shift;
	# This deserves an exception object.
	confess 'render() may only be called once per request!'
		if defined $self->response->buffer
	;
    confess 'render() called without parameters set or parameters is not a HASH ref'
        unless defined $self->parameters and ref $self->parameters eq 'HASH'
    ;
	my %params = @_;
	my $view = $self->$validate_view_parameter( delete $params{view} );
	if (! defined $view) {
		$view = $self->registered_name() . '/' . $self->parameters->{action}
			if defined $self->registered_name()
			and defined $self->parameters->{action}
		;
	}

	$params{view} = $view;
	$self->$determine_default_layout( \%params );

	my $result = $self->$render_internal( %params );
	$self->response->buffer( $result );
    $self->response->headers->content_type( $self->content_type || $self->default_content_type )
        if ! defined $self->response->headers->content_type
    ;
    $self->response->headers->status( '200 OK' )
        if ! defined $self->response->headers->status
    ;
	return 1;
}

sub redirect {
	my $self = shift;
	my %params = @_;
    $self->response->headers->content_type( $self->content_type || $self->default_content_type )
        if ! defined $self->response->headers->content_type
    ;
    $self->response->headers->status( defined($params{status}) ? delete $params{status} : '301 moved' );
    $self->response->headers->location( $self->url( %params ) );
    return 1;
}

sub prepare_parameters {
	my $self = shift;
	my $path_params = shift;
	my %parameters;
	if ($self->request->method eq 'get') {
		%parameters = $self->request->get_variables;
	}
	elsif ($self->request->method eq 'post') {
		%parameters = $self->request->post_variables;
	}

	@parameters{ keys %$path_params } = values %$path_params;
	$self->parameters( \%parameters );
	return;
}

my $transform_parameters = sub {
	my $self   = shift;
	my $params = shift;

    # transform null-separated values into arrays and where param name ends in []
    for my $key (grep { $_ =~ /\[\]$/ or (defined $params->{$_} and $params->{$_} =~ /\0/) } keys %$params) {
        my $value = $params->{$key};

        $params->{$key} = [];
        if (defined $value) {
            push @{$params->{$key}}, split /\0/, $value;
        }
    }

	my %seen;
	for my $parameter (sort { $a cmp $b } grep /\[\w*\]$/, keys %$params) {
		my $value = delete $params->{$parameter};
		my ($name, $targets) = ($parameter =~ /^(.+?)\[(.*?)\]$/);
		my @names = split /]\[/, $targets;
		my $target = $params;
		while (@names) {
			$target->{$name} = {}
				if ref($target->{$name}) ne 'HASH'
			;
			$target = $target->{$name};
			$name = shift @names;
		}
		$target->{$name} = $value;
	}

	return $params;
};

around parameters => sub {
	my $code = shift;
	my $self = shift;
	return $self->$code unless @_;
	my $value = shift;
	return $self->$code( $value )
		if ! defined $value
	;
	return $self->$code( $self->$transform_parameters( $value ) );
};

sub caches_page {
    my ($self, $action) = @_;
    confess sprintf('Unrecognized action in Controller "%s": "%s"', ref($self), $action)
        unless $self->can($action)
    ;
    return $self->cache_pages->{$action};
}

sub _page_cache_handler_function {
    my ($self, $method_name,) = @_;
    my ($handler, $sub, $invocant, %opt);
    $handler = $self->_determine_page_cache_handler;
    if ($sub = UNIVERSAL::can( $handler, $method_name )) {
        $invocant = $handler;
    }
    else {
        $invocant = 'IC::Controller::PageCache';
        $sub = $invocant->can($method_name);
        $opt{cache_handler} = $handler;
    }
    return sub {
        return $invocant->$sub( @_, %opt, );
    };
}

sub _determine_page_cache_handler {
    my $self = shift;
    my $handler = $self->page_cache_handler if $self->blessed;
    return $handler || $self->default_page_cache_handler;
}

sub check_page_cache {
    my ($self, $params) = @_;
    return if $self->page_cache_no_reads;
    return if $self->request->method ne 'get';
    my $result = $self->_page_cache_handler_function('get_cache')->( parameters => $params );
    return if ! defined $result;
    $self->response->buffer( \$result );
    $self->response->headers->status( '200 OK' );
    $self->response->headers->content_type( $self->content_type || $self->default_content_type );
    return $self->response;
}

sub set_page_cache {
    my ($self, $params) = @_;
    return if $self->request->method ne 'get'
        or ! defined( $self->response->buffer )
        or $self->response->headers->status !~ /^200\s+ok$/i
    ;
    return $self->_page_cache_handler_function('set_cache')->(
        parameters => $params,
        data => ${$self->response->buffer},
    );
}

sub process_request {
	my $invocant = shift;

	# TODO: oh, my kingdom for an exception object!
	confess 'process_request() may only be called against a package!'
		if ref $invocant
	;

    $invocant->process_initialization();

	my %params = @_;
    my (
        $route_handler,
        $path,
        $path_params,
        $request_class,
        $cgi,
        $headers,
        $controller,
        $action_name,
        $error_invocant,
        $has_route,
    );
    $error_invocant = $invocant;
    eval {
        $route_handler = delete($params{route_handler}) || 'IC::Controller::Route';
        # my, my, more exception objects necessary.
        confess 'process_request() requires a valid route_handler!'
            unless defined $route_handler and $route_handler->can('parse_path')
        ;

        $path = $route_handler->canonize_path( delete($params{path}) );
        # no exceptions if $path is empty; routes could theoretically handle that.
        $path = '' if ! defined($path) or $path !~ /\S/;
        $path_params = $route_handler->parse_path( $path, $params{headers}->{REQUEST_METHOD} );
        return undef unless ref $path_params eq 'HASH';
		$has_route++;
        ($request_class, $cgi, $headers)
            = delete( @params{qw( request_class cgi headers )} )
        ;
        unless (defined $cgi) {
            warn "cgi hash ref not provided, setting empty hash ref";
            $cgi = {};
        }

        $controller = $invocant->get_by_name( $path_params->{controller}, %params );
        # Who needs exception objects?  We don't need 'em!  Not here!
        confess "process_request() requested an unknown controller ('$path_params->{controller}')!"
            unless defined $controller
        ;
        
        # Now the instantiated controller should be the error handler
        $error_invocant = $controller;

        $controller->route_handler( $route_handler );

        $request_class = __PACKAGE__ . '::Request'
            unless defined($request_class) and length $request_class
        ;
        $controller->request(
            $request_class->new(
                cgi		=> $cgi,
                headers	=> $headers,
            )
        );
            
        $action_name = $path_params->{action};
        my $caches_page = $controller->caches_page( $action_name );
        # bind the helpers to the current controller...
        IC::Controller::HelperBase->bind_to_controller( $controller );
        
        if (! ($caches_page and $controller->check_page_cache( $path_params )) ) {

            $controller->prepare_parameters( $path_params );

            my $action = $controller->can( $action_name );
            confess "process_request() requested an unknown action ('$path_params->{action}')!"
                unless defined $action
            ;
            $controller->$action();

            $controller->set_page_cache( $path_params ) if $caches_page;
        }
    };

    return $has_route ? $controller->response : undef
        unless $@
    ;
    return $error_invocant->handle_error(
        IC::Controller::Exception::Request->new(
            error           => $@,
            route_handler   => $route_handler,
            path            => $path,
            path_params     => $path_params,
            request_class   => $request_class,
            cgi             => $cgi,
            headers         => $headers,
            controller      => $controller,
            action          => $action_name,
        )
    ) if defined($error_invocant->error_handler);
    die $@;
}

sub process_initialization {
    my $self = shift;
}

sub url {
    my $self = shift;
    my %params = @_;
    if (! defined $params{controller} and ! defined $params{href}) {
        if (defined IC::Controller::HelperBase->controller
            and defined IC::Controller::HelperBase->controller->registered_name
        ) {
            $params{controller} = IC::Controller::HelperBase->controller->registered_name;
        }
        else {
            $params{controller} = $self->registered_name;
            $params{route_handler} = $self->route_handler
                if ! defined $params{route_handler}
            ;
        }
    }
    return IC::Controller::Route::Helper::url( %params );
}

sub handle_error {
    my ($self, $err) = @_;
    my $handler = $self->error_handler;
    die sprintf("No error handler specified for %s\n", blessed($self) || $self)
        unless defined($handler)
    ;
    die sprintf("Invalid error handler specified: %s\n", $self->error_handler)
        if !(ref($handler) or $handler = $self->can($handler))
    ;
    return $self->$handler($err);
}

1;

__END__

=head1 ACKNOWLEDGEMENTS

Thanks to Stevan Little for Moose and Class::MOP, which provide the object system
for B<IC::Controller> and its related modules.

Thanks to Rails, which pushed the state of the art and gave us lots of good design ideas.

Thanks to Catalyst, which also gave us some good design ideas.

=head1 CREDITS

Original author: Ethan Rowe (End Point Corporation; ethan@endpoint.com)

=cut
