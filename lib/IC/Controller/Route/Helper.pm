package IC::Controller::Route::Helper;

use Vend::Interpolate ();
use Vend::Util ();

use strict;
use warnings;

use Data::Dumper ();
use Exporter;
use Scalar::Util qw(blessed);
use Carp;

use IC::Controller::HelperBase;

use base qw(Exporter IC::Controller::HelperBase);

# Truly lame.
Vend::Util::setup_escape_chars;
 
@IC::Controller::Route::Helper::EXPORT = qw(
    url
    cache_helper
    image_path
);

sub url {
    my %options = @_;
    my ($url, $controller, $action, $parameters, $get, $handler, $binding, $method)
        = delete @options{qw(
            href
            controller
            action
            parameters
            get
            route_handler
            binding
            method
        )}
    ;
    
    if (defined $binding) {
        # another exception object needed!
        croak 'url() can only accept binding objects within the "binding" parameter!'
            unless blessed($binding)
        ;
        #        and $binding->isa('IC::Controller::Route::Binding')
        $url = $binding->href;
        $controller = $binding->controller;
        $action = $binding->action;
        $parameters = $binding->url_parameters;
        $get = $binding->get_parameters;
        $handler = $binding->route_handler;
    }
    
    my $current_controller = __PACKAGE__->controller;
    
    $handler = (
        defined($current_controller) && defined($current_controller->route_handler)
            ? $current_controller->route_handler
            : 'IC::Controller::Route'
    )
        unless defined $handler
            and ref($handler) || length($handler)
    ;
    
    if (! defined $url ) {
        $controller = $current_controller->registered_name
            if ! defined $controller or ! length $controller
        ;
        # ahoy, cap'n; we need an exception object!
        croak 'url() requires a controller and an action!'
            unless defined $controller
                and defined $action
                and length $controller
                and length $action
        ;
        my %path_params;
        %path_params = %$parameters
            if defined $parameters
        ;
        $path_params{controller} = $controller;
        $path_params{action} = $action;
        $path_params{method} = $method if $method;
        $url = $handler->generate_path( %path_params );
        croak "url() could not find a route for the requested controller/action: $controller:$action ($handler)"
            unless defined $url
        ;
        # MVC paths don't need a .html
        $options{add_dot_html} = 0
            unless defined $options{add_dot_html}
        ;
    }
    
    if (ref $get eq 'HASH' and %$get) {
        $get = join("\n", map { "$_=$get->{$_}" } sort { $a cmp $b } keys %$get);
        $options{form} = $get;
    }
    else {
        $get = undef;
        delete $options{form};
    }
    
    # ouch!  Seriously lame, but only option to be usable outside full IC process...
    $Global::UrlJoiner ||= '&';
    return Vend::Interpolate::tag_area( $url, undef, \%options, );
}

sub cache_helper {
    my ($a, $b, $c, $day, $mon, $year) = localtime;
    my $date = ($year + 1900) . $mon . $day;
    
    return "x=$date";    
}

1;

__END__

=pod

=head1 NAME

IC::Controller::Route::Helper -- helper module providing url-generation tools

=head1 DESCRIPTION

Provides the B<url()> function for generating URLs within an MVC-enabled Interchange application;
built upon the Interchange core B<area> tag, meaning that the URL generation is consistent with
established practice (except as otherwise documented here), and further reliant upon the MVC
routing objects (B<IC::Controller::Route>) for constructing paths within the MVC object family.
Also provides the B<cache_helper()> function for use in preventing old cached js and css and the 
B<image_exists()>, and B<get_item_image_url> functions as replacement subsets of the old ITL image tag.

=head1 USAGE

Usage of this module is fairly straightforward, as it only provides one function, and that
function should feel fairly familiar to anyone accustomed to B<IC::Controller::Route>->B<generate_path()>
or Interchange's B<$Tag>->B<area()>.  There are a few differences with the area tag, in that
the "form" variables are specified via a I<get> parameter (since they are in fact "get" variables),
and are specified via a hash instead of a stringified hash mess.

  # import url() into our current package.
  use IC::Controller::Route::Helper;
  
  # print a URL for controller 'foo' action 'test'
  # with URL params item_id => 1 and show => 1,
  # which, with appropriate routing, might look something like:
  # http://your.domain.com/cgi-bin/catalog/foo/test/1/1
  print url(
      controller => 'foo',
      action     => 'test',
      parameters  => {
          item_id => 1,
          show    => 1,
      },
      no_session  => 1,
  );
  
  # Put some GET variables in there, so we might get something like:
  # http://your.domain.com/cgi-bin/catalog/foo/test?moose=bullwinkle&squirrel=rocky
  print url(
      controller => 'foo',
      action     => 'test',
      get        => {
          moose    => 'bullwinkle',
          squirrel => 'rocky',
      },
      no_session => 1,
  );
  
  # Or just a standard Interchange page, no MVC at all...
  # http://your domain.com/cgi-bin/catalog/some_page
  print url(
      href => 'some_page',
  );
  
  # and, of course, full URLs are unchanged; this prints:
  # http://www.google.com
  print url(
      href => 'http://www.google.com',
  );

Pretty straightforward.  Use this instead of the area tag.

Note that routing is a tricky subject here, since any given daemon may contain multiple
route objects/packages.  The default behavior is for the routing to be done by the route
handler serving the current request.  Assuming your MVC processes aren't peeking under
the hood too much, you should find that the routing Just Works within any given process,
as the route object/package used will always be the same route/package that got the processing
into the MVC subsystem in the first place.  If you need to use an alternate routing object
for whatever reason, see the I<route_handler> option for B<url()>.

=head1 FUNCTIONS

=over

=item B<url( %parameters )>

Returns the full URL (including protocol, domain name, catalog paths, etc.) for the
resource identified via 'href', 'controller', 'action', and 'parameters', along with
any GET variables specified via 'get'.

Valid options to specify in I<%parameters>:

=over

=item I<href>

The actual resource/page to link to; overrides controller/action if present.  Use this
to specify standard Interchange pages, static files served through Interchange, etc.
Use of this parameter makes B<url()> exactly analogous to the Interchange B<area> tag.

=item I<controller>

The registered name of the controller to which the link should refer.  If not specified
explicitly, will default to the registered name of the controller assumed to be handling
the current request (i.e. the controller return via IC::Controller::HelperBase->controller()).

=item I<action>

The action to be invoked on the controller specified via the resulting link.

=item I<parameters>

Additional parameters to be encoded via routing within the path portion of the URL (not
via GET parameters; do not conflate the two).  This should be a hashref of name/value
pairs.

=item I<method>

The intended HTTP method for the URL in question; routes may or may not be configured with REST
in mind, in which case you may have method-specific routes.

If unspecified, uses default behavior of the underlying generate_path logic, meaning "get" is assumed.

=item I<get>

A hashref of name/value pairs to encode as GET variables within the URL.  This goes through
Interchange's area tag "form" parameter, meaning that the names/values must not contain
newlines, line feeds, etc.  The I<get> parameter will B<always> override anything you might
try to put in I<form>; the reason for this is that these variables are in fact GET variables
and not form postings, so the name should reflect this; furthermore, using a hash as the means
of specifying the name/value pairs is cleaner for programmers than is messing with stringified
hashes.

=item I<route_handler>

The object or package to use for routing (path generation from controller/action/parameter
values); this is provided for specifying overrides of the default behavior.  By default,
routing is determined by the route_handler attribute of the current controller (as returned
by B<IC::Controller::HelperBase>->B<controller()>, failing over to B<IC::Controller::Route>
if no current controller exists).

=item I<binding>

An instance of B<IC::Controller::Route::Binding>, fully configured with all necessary component
and "widget" parameters, mappings, and such.  When I<binding> is present, it rules the roost, resetting
the values of I<href>, I<controller>, I<action>, I<parameters>, I<get>, and
I<route_handler> appropriately based on
the attributes/methods of the binding object.  This happens early-on in the process, meaning that
the resulting behaviors one sees from various combinations of these parameters will still manifest,
only based on the values provided by the binding object rather than in the main B<%parameters> hash.

=back

All other name/value pairs provided in I<%parameters> passes through to the underlying Interchange
B<area()> call, meaning that things like I<no_session>, I<no_count>, etc. may be specified,
as well as flags like I<secure> and so on.

=back

=over

=item B<cache_helper>

This poorly-named function returns a string with the current datestamp to aid in preventing the 
caching of old javascript and css files for more than a day.
A better solution in the future would be to increase the granularity of this datestamp, and
to update it specific to the resource being included.

=back

=cut

