package IC::Component;

use strict;
use warnings;

use IC::Controller::HelperBase ();
use IC::Controller::Route::Helper ();
use IC::Controller::Route::Binding ();
use Moose;
use Moose::Util::TypeConstraints;
use IC::Log::Logger::Moose;

extends 'IC::Log::Logger::Moose';

subtype UrlBinding
    => as Object
    => where { $_->isa('IC::Controller::Route::Binding') }
;

coerce UrlBinding
    => from HashRef
        => via { IC::Controller::Route::Binding->new( %{ $_ } ) }
;

has controller => (is => 'rw', isa => 'IC::Controller', );

sub binding_transform {
    my $self = shift;
    my $arg = shift;
    $arg = IC::Controller::Route::Binding->new( %$arg )
        if ref($arg) eq 'HASH'
    ;
    # wait; you mean you haven't bothered with exceptions yet?  dummy.
    confess 'registered bindings must be or coerce to an instance of IC::Controller::Route::Binding!'
        unless $arg->isa( 'IC::Controller::Route::Binding' )
    ;
    return $arg;
}

sub register_bindings {
    my $invocant = shift;
    # yet another place where exception objects would be helpful...
    confess 'register_bindings() may only be invoked via a package!'
        if ref($invocant)
    ;
    my $meta = $invocant->meta;
    confess 'register_bindings() cannot find the Moose Metaclass object!'
        if !defined($meta)
    ;
    # use the meta class to wrap each attrib with an around method modifier...
    for my $attribute (@_) {
        $meta->add_attribute( $attribute, is => 'rw', isa => 'UrlBinding', coerce => 1, );
        my $newsub = sub {
            my $oldsub = shift;
            my $self = shift;
            return $self->$oldsub() unless @_;
            return $self->$oldsub( $self->binding_transform( @_ ) );
        };
        $meta->add_around_method_modifier($attribute, $newsub);
    }
}

sub content {
    my $invocant = shift;
    my $obj;
    if (!ref($invocant)) {
        # convenience function; object is created automatically and thrown away
        # if called through a package rather than a blessed ref.
        $obj = $invocant->new( @_ );
    }
    else {
        $obj = $invocant;
    }
    # a wonderful place for an exception object.  Whaddya say?
    confess 'content() cannot be loaded since the component does not implement an execute() method'
        unless $obj->can('execute')
    ;
    return $obj->execute( @_ );
}

sub render {
    my $self = shift;
    my %params = @_;
    my $controller
        = delete($params{controller})
          || $self->controller
          || IC::Controller::HelperBase->controller
    ;
    # Yikes.  Guess what I'm about to say!
    confess 'Unable to render without a controller!'
        unless $controller
    ;
    delete $params{layout};
    my $view = $params{view};
    # and again...
    confess 'Unable to render without a view!'
        unless defined $view
            and ref($view) eq 'ARRAY' && @$view
            or !ref($view) && length($view)
    ;

    # prepare view array.
    if (!ref($view)) {
        my @views;
        push @views, $controller->registered_name . '/' . $view
            if defined $controller->registered_name
        ;
        push @views, 'components/' . $view;
        $params{view} = \@views;
    }
    
    # prepare view context from object attributes
    if (ref($params{context}) ne 'HASH') {
        my %context;
        for my $attrib ($self->meta->get_all_attributes) {
            my $name = $attrib->name;
            my $sub = $self->can($name);
            $context{$name} = $self->$sub();
        }
        $params{context} = \%context;
    }
    
    # we use the controller to do the actual render, so the controller's view settings rule.
    return $controller->render_local( %params );
}

sub url {
    my $self = shift;
    return IC::Controller::Route::Helper::url( @_ );
}

__PACKAGE__->register_bindings( 'binding' );

1;

__END__

=pod

=head1 NAME

IC::Component -- a base object class for business logic/presentation "components" within MVC

=head1 DESCRIPTION

"Components?" you query derisively.  "What for?  I thought the basic MVC pattern solved everything.
Why do we need more thingies?  Can't I just write controllers and views and whatnot?"

Well, sure you could, but your code reuse might suffer.  Common bits of logic/presentation combinations
can be achieved in a variety of ways within the MVC subsystem, and sharing thereof can be achieved via
inheritance of controllers.  However, this means that potentially messy inheritance chains are necessary
in order to offer up reusable widgets.

So, in comes B<IC::Component>.  This is kind of like the MVC pattern itself in that the "component"
implements arbitrary business logic using whatever it needs to use (i.e. models and such) and then
"renders" content.  However, components are lighter-weight than are B<IC::Controller> instances within
our MVC system, and are not publicly exposed in any direct fashion; they are reusable widgets that do
stuff, and they are used by controllers to build up full responses piece by piece.

B<IC::Component> is dumber than its wise cousin, B<IC::Controller>.  B<IC::Controller> knows how
to process requests.  It knows how to spit out URLs, because it knows about the current routing rules.
It knows where views are supposed to live.  B<IC::Component> doesn't know any of this stuff by itself;
therefore, it expects to be given a controller or a view object in order to do any rendering, and it
really needs a controller if it's going to do any URL generation.

Furthermore, since URLs are always specific to a particular controller, and a component needs to be
reusable across controllers, the component must be told the critical parameters that would go into
any URL it might build: the controller name, the action, the URL parameters, GET parameters, etc.  The
component by itself will flail helplessly if it needs to create URLs, but if a controller tells it
what stuff is important, it'll do just fine.

=head1 USAGE

The basic assumption of B<IC::Component> is that you want to produce some rendered content, whether
that content is text, markup of some sort, etc.  Fancier components may require some external manipulation
to perform their tasks, but in principle, the average component should simply be called upon to render
itself based on some arbitrary information.  So that's what B<IC::Component> attempts to make simpler:

  package MyApp::Foo;
  use IC::Controller;
  use Moose;
  extends qw(IC::Controller);
  use MyApp::Component::Widget;
  
  sub some_action {
      $self = shift;
      # set some templating attribute based on the component...
      $self->template_left_content(
          MyApp::Component::Widget->content(
              controller    => $self,
              bindings  => {
                  action    => 'some_action',
                  controller_parameters => { some_var => $self->parameters->{some_var}, },
              },
              widget_param1 => 'something_or_other',
              widget_param2 => 'something_else_or_otherwise',
          ),
      );
      # And thus, the template_left_content attribute of the controller
      # received the content rendered by MyApp::Component::Widget,
      # based on the various parameters.
      $self->render(
          context => {
              some_var => $self->parameters->{some_var},
          }
      );
      return;
  }

=head1 ATTRIBUTES

All attributes are Moose-style, per usual, unless otherwise noted.

=over

=item B<controller>

Get/set the component's reference to the controller with which the current work done is associated; the component
can use the controller's view settings and url generation routines to be certain that the proper view directory,
helpers, etc. are used, in addition to the correct routes when generating URLs.

=item B<binding>

A registered binding attribute (see B<register_bindings()> below) provided as a default attribute for
all components, merely as convenience.  There is no rule specifying that your component must make
use of this, nor is there any additional magic associated with it beyond the normal magic of
registered binding attributes.

=item B<get_logger, set_logger, has_logger>

A general logging attribute with get, set, and predicate accessors.  This allows a component instance to
use its own logging object as needed.  When this attribute is set, the B<logger()> method will return
the value; otherwise, B<logger()> will return a default.

This attribute and its accessors are inherited from B<IC::Log::Logger::Moose>; see that module for
details.

=back

=head1 PUBLIC METHODS

=over

=item B<content( %parameters )>

The primary means of working with a component as a consumer, B<content()> does whatever
it is that the component does and returns the result (which is presumably content to 
return to the client, given the webappy nature of the framework).  The assumption is
that the component does one thing and one thing only, and the particulars of how it should
do said thing can be communicated entirely parameter entries (in I<%parameters>) specific
to the component in question.  This means that all components have the same basic interface
for actually getting results, and would largely differ (if well-designed) in their
attributes.  That comment is intended as a design hint.

When B<content()> is invoked against an object, it acts like a regular object method.
However, as an additional bit of helpful magic, B<content()> can be invoked directly
from the component package name, and it will internally create an instance of the
component to handle the logic, passin the I<%parameters> hash through to
the constructor.  This means that controllers relying on components can get a well-designed
component to do its entire job in a single call to B<content()> with instantiating the
component at all:

  use Some::Component;
  ...
  my $widget_content = Some::Component->content(
      binding => {
          href => 'http://foo.bar.com',
      },
      foo => 'bar',
  );
  return "The component gave me: $widget_content";

Since the constructor function includes additional magic for transforming hashes into
actual B<IC::Controller::Route::Binding> objects (see B<register_bindings()>), the
package-based invocation of B<content()> is quite powerful and expressive and should,
in general circumstances, entirely eliminate the need to get individual instances of
components to work with them effectively.  The only situation in which this would obviously
not be the case is if the component to be used expected parameters in B<content()> whose
name(s) collide with the name(s) of component attribute(s).  This is easily avoided by
designing your components sensibly.

Internally, all parameters passed to B<content()> go first to the constructor (when invoked)
via the package name) than to B<execute()>.  What happens to the parameters from there
depends on the component implementation of B<execute()>, and should be a documented part
of the component's interface.  As mentioned, good design would probably favor use of
attributes and eschew special parameters to B<render()> entirely.

=back

=head1 INTERNAL METHODS

Given the wide-open, we're-all-friends Perl idiom of OOP, internal methods are not strictly "internal",
as they can be invoked from outside the object.  By "internal" we simply mean that these methods are
intended to be called by the component instances themselves for their own internal processes, rather
than by users of the component instances.

=over

=item B<execute( %parameters )>

The B<execute> method needs to be implemented by all B<IC::Component> subclasses; this method is
called by B<content()> and is expected to perform the actual work implemented by the component subclass.
The return value of B<execute()> should be thought of as the component's return value for B<content()>,
and is thus the content/data/etc. that the caller wants to get out of the component.

The I<%parameters> received are identical to those received by B<content()>.  Therefore, take the
B<content()> method into account when trying to sort out what parameters to expect in this hash; it
is up to the implementor of the B<IC::Component> subclass to choose reasonable parameters for their
own purposes.  If the subclass has a good set of attributes and is simple in its design, it may not
be necessary to perform any processing on I<%parameters> at all, and B<execute()> can ignore the hash
and simply base its operations on the instance's attributes.

There is no limit to the complexity of what can be done beneath the hood in your B<execute()> implementation,
but consider that the simpler your component, the easier it is to test, maintain, etc., and thus the more
dependable it is.  But for what in software engineering is this not typically the case?

Note that users of your components are free to call B<execute()> directly, but the wonderful magic
of B<content> will be lost in doing so.  The whole purpose of B<content> is to make it really easy
to work with components, so direct use of B<execute()> is generally discouraged.

=item B<render( %parameters )>

Given a view and other parameters, renders the view and returns the resulting content; use
this within your components to build content to return to the user of the component (assuming
that's what your component is actually about).  The B<render()> method is a wrapper around
the B<render_local()> method of the B<IC::Controller> object, the means of location to
be discussed momentarily.

See the B<IC::Controller> documentation for B<render_local()> to understand the workings
of B<render()> here; note, however, the following various exception:

=over

=item I<layout>

There is no I<layout> option for B<render()>.  The same functionality can be achieved
as needed via multiple calls to B<render()>, marshaling the rendered content into
subsequent invocations.

=item I<view>

When given a simple scalar for the I<view> parameter, B<render> will look for that
view file first in a controller-specific location (i.e. a subdirectory named for
the controller's B<registered_name>) and then in a general component space (the 'components')
subdirectory.  These directories are naturally relative to the B<view_path> of the controller
used to actually do the rendering behind the scenes by B<render()>.

=item I<context>

When provided, I<context> hash parameter acts just as it does in B<render_local()>; when
not provided, B<render()> will marshal all known attributes of the component into the view.
This is somewhat similar to the behavior of layouts when rendering in a controller.  This
default is intended to make your life easier; store relevant stuff about the component
in its attributes, and then you don't need to worry about what gets marshaled when you
call B<render()>.  It is especially helpful when one considers that binding object attributes
set up with B<register_bindings()> would be automatically marshaled...

=item I<controller>

The controller through which rendering actually takes place may be specified explicitly
via the I<controller> parameter; however it is typically not strictly necessary to do so;
B<render()> will look in a variety of reasonable places to determine what controller to
use, thusly:

=over

=item 1.

The I<controller> parameter in the I<%parameters> list provided to B<render()>.

=item 2.

The B<controller> attribute of the component itself.

=item 3.

The bound controller of the current process (B<IC::Controller::HelperBase>->B<controller()>).

=back

If no controller can be identified, then an exception is thrown, as no rendering can
actually take place.  This is entirely intentional.  Components are dumb, remember?

=back

The importance of the controller in the B<render()> call cannot be overstated; it determines
where the views live (via the controller's B<view_path()>), what helper modules are made
available to the views, etc.  Fortunately, if you go with the default behavior, you'll
generally be perfectly happy.  Setting a controller explicitly should only be necessary
if you're doing very specific things with your component, or if you're using a component
outside the context of the main MVC processing path.

=item B<register_bindings( @bindings_list )>

Given a list of desired attribute names in I<@bindings_list>, B<register_bindings()> creates each attribute
named, wrapped with magical behavior that makes your component easier to use.  Per attribute named,
the set function is overridden to:

=over

=item *

Transform the argument provided to the set function into a binding object (i.e. an instance of
B<IC::Controller::Route::Binding>) if it isn't one already.

=item *

Type-check the set argument to ensure that it is indeed a binding object (this takes place after
the attempted transform).

=back

The benefit of this is simple: consumers of your component don't need to build all the binding
objects manually, and can instead pass appropriate hashrefs to your component's constructor
per registered binding attribute, and the constructor (or subsequent set actions on individual
registered binding attributes) will automatically build the binding object from the hashref
provided.

This becomes even more obviously beneficial when you consider the B<content()>
method and the fact that it magically creates an instance of the component internally if invoked
against the component's package name instead of a component instance; thus, code that relies
on your component can get your component to do everything it needs (usually) with a single
call like:

  Your::Component->content(
      binding => {
          controller => $this_controller->registered_name,
          action => $this_action,
          url_names => ['x'],
          name_map => { foo => 'x', },
      },
      foo => $this_controller->parameters->{x},
      blah => 'blah',
  );

In this example, the 'binding' is a registered binding attribute, so the hash provided
will be converted to an actual binding object based on the hash; the controller using
Your::Component didn't need to do anything beyond pass the right stuff to B<content()>.

All you need to do in Your::Component when building links, then, would be to be sure to
use the B<binding()> attribute when building links via B<url()>.  The registered binding
attributes makes it easy for you to do things correctly, and easy for consumers of your
component to make sure your component does things correctly.

So, to use B<register_bindings()> in your B<IC::Component>-derived implementations:

=over

=item *

Call B<register_bindings()> within the package, provided a list of the relevant desired attribute names.
Like this:

  package Your::Component;
  use Moose;
  extends qw(IC::Component);
  __PACKAGE__->register_bindings(qw(
      update_binding
      delete_binding
      refresh_binding
  ));
  ...

=item *

There is no need to create the attributes beforehand with the 'has' function; B<register_bindings()>
takes care of attribute creation for you.

=back

Pretty simple.

=item B<binding_transform( $binding )>

Invoked automatically by the set function of any attribute registered as a binding
via B<registered_bindings()>, B<binding_transform()> will check its first argument and
transform it to a new B<IC::Controller::Route::Binding> object if needed.  The transformed
argument (or the original argument if no transform was necessary) will be returned.

There's no reason to use this directly; it's part of the magic of registered binding attributes,
and is simply present to make your life easier.  It's implemented as regular method rather than
a lexical (private) method so you can override it should the urge strike.

=item B<url( %params )>

Builds and returns a URL based on the parameters provided in I<%params>.  This is basically a wrapper
around B<IC::Controller::Route::Helper::url()>; refer to the appropriate documentation for
details.  While nothing forces this upon you, it is expected that calls to B<url()> within a component
implementation (or its views) will typically rely on a binding attribute known to that component, thus
minimizing the coupling between a component and any one controller.

=item B<logger()>

Return a logging object, based on the component object's state (I<get_logger()>) and falling back
to a system-wide default.  See B<IC::Log::Logger::Moose> for details.

Note that the I<logger()> method does not consider the logging details of the controller that was
provided to the component; that controller may have its own logger object, but the component's
I<logger()> is entirely independent thereof.

If you want a particular component to always use the same logging as the component that invoked
it, then you can try something like this within that component:

 $self->set_logger( $self->controller->logger );

Simple enough to solve yourself as needed.

=item B<get_logger_default()>

A package-level method (it does not need to be invoked on a specific instance) that determines the
default logging construct to use with B<logger()>.  Inherited from B<IC::Log::Logger::Moose>.
See that module for details.

=back

=head1 SEE ALSO

=over

=item B<IC::Controller>

The controller base class.

=item B<IC::Controller::Route::Binding>

Route/URL binding class.

=item B<IC::View>

General interface for rendering views.

=item B<IC::Log::Logger::Moose>

Base class of B<IC::Component> providing the logging interface/attributes.

=back

=head1 CREDITS

Author: Ethan Rowe (ethan@endpoint.com)

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
