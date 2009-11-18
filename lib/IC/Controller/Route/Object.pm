package IC::Controller::Route::Object;

use strict;
use warnings;

use Moose;
use Data::Dumper;

=pod

=head1 NAME

IC::Controller::Route::Object -- Express application paths as a pattern

=head1 DESCRIPTION

IC::Controller::Route::Object instances represent application URL/parameter
mappings; given a pattern and set of default parameter values, an instance can
both generate and parse URLs that match the pattern.

=head1 USAGE

Think of your URLs as a public interface to underlying resources and behaviors.
The same URL should always provide the same resource, and the same resource should
ideally always use the same URL.  When approaching URLs in this fashion, the URL
becomes more akin to a functional interface.  This is part of the point of RESTful
design.  This is not coincidental.

For a given URL, we want to derive a B<controller> (the module in which the
behavior lives) and an B<action> (the actual behavior to invoke within the controller).
Furthermore, we may need to derive any number of arbitrary parameters from the URL,
as well as provide defaults for parameters not necessarily expressed explicitly
within the URL itself.

We may, for instance, want all URLs of the form "foo/list/I<some_value>" to
invoke the "list" action on the "foo" controller, with I<some_value> being the identifier
of the thing to be listed.

A IC::Controller::Route::Object instance could express this as:
  my $obj = IC::Controller::Route::Object->new(
      pattern    => 'foo/list/:some_value',
	  controller => 'foo',
	  action     => 'list',
  );
  
  # Parse a path
  my $params = $obj->parse_path( 'foo/list/0001' );
  printf "Controller: %s Action: %s some_value: %s\n", @$params{qw(controller action some_value)};
  # prints "Controller: foo Action: list some_value: 0001"
  
  # Build a path
  print $obj->generate_path( controller => 'foo', action => 'list', some_value => 256, );
  # prints "foo/list/256"

However, this path sure looks like a pattern that could be generalized; the controller
and action we're using are already expressed within the path itself.  So we can make
a more general-use pattern that would work with any number of controllers and actions.

  my $obj = IC::Controller::Route::Object->new(
      pattern => ':controller/:action/:argument',
	  controllers => \@known_controller_names,
  );
  
  # get controller 'foo' action 'list' argument 'blah'
  $obj->parse_path( 'foo/list/blah' );
  
  # get controller 'building', action 'exit', argument 'now'
  $obj->parse_path( 'building/exit/now' );
  
  # get 'spam/eat/plateful'
  $obj->generate_path(
      controller => 'spam',
	  action     => 'eat',
	  argument   => 'plateful',
  );

The different segments of the path can be made "optional" by providing default values
for them.  The default merely needs to exist in the B<defaults> property of the object
instance; an undefined value is a valid default, which truly is a way of making a
particular segment/parameter optional.

When default values are provided for parameters, IC::Controller::Route::Object will
take them into account when both parsing and generating paths; the defaults are used
in path generation to ensure that only minimal paths are created -- the object will
generate the path that most concisely expresses the controller/action/parameters/defaults
combination.  Consequently, while the same pattern/defaults combination could theoretically
map multiple URLs to the same set of resulting parameters, the same set of resulting parameters
as inputs to B<generate_path()> will always result in the shortest possible path that
expresses those parameters.

  my $obj = IC::Controller::Route::Object->new(
      pattern     => ':controller/:action/:argument',
	  controllers => \@known_controller_names,
	  defaults    => {
          argument => undef,    # this merely makes 'argument' optional
		  action   => 'index',  # 'action' will default to 'index' if not provided
	  },
  );
  
  # get controller 'a', action 'b', argument 'c',
  $obj->parse_path( 'a/b/c' );

  # get controller 'foo', action 'bar', no argument.
  $obj->parse_path( 'foo/bar' );
  
  # get controller 'test', action 'index', no argument
  $obj->parse_path( 'test' );
  
  # get path 'a/b/c',
  $obj->generate_path( controller => 'a', action => 'b', argument => 'c', );
  
  # get path 'foo/bar' as no argument is provided and so third segment isn't necessary
  $obj->generate_path( controller => 'foo', action => 'bar', );
  
  # get path 'test', as no action or argument are provided
  $obj->generate_path( controller => 'test');
  
  # similarly, get path 'test' because action provided matches the default
  $obj->generate_path( controller => 'test', action => 'index', );
  
  # get 'me/index/you'; even though the action is the default, it is only possible
  # for the path to express the argument if the action is expressed as well.
  $obj->generate_path( controller => 'me', argument => 'you', );

In addition to this, you can have a URL match any number of trailing path segments
with each segment going as an array entry.  Use the "*paramname" for this.  This array
syntax eats whatever remains in the path, so it must be the last segment within your
pattern.  An array parameter will always default to an empty arrayref ([]) if not
specified in the B<defaults> hash.

  my $obj = IC::Controller::Route::Object->new(
      pattern     => ':controller/:action/*segments',
	  controllers => \@known_controller_names,
	  defaults    => { action => 'index', },
  );
  
  # get controller 'a', action 'b', segments [qw( c d e )]
  $obj->parse_path( 'a/b/c/d/e' );
  
  # get controller 'foo', action 'index', segments []
  $obj->parse_path( 'foo' );
  
  # get path 'foo/bar/blah/blee/blue'
  $obj->generate_path( controller => 'foo', action => 'bar', segments => [qw(blah blee blue)], );
  
  # get path 'cow/moo'
  $obj->generate_path( controller => 'cow', action =>' moo', segments => [] );

Literal segments can be scattered throughout your URL pattern, meaning that they
do not correspond to a particular parameter and must match exactly when parsing URLs.
Use of literals at the start of URL patterns can be helpful to serve as a sort of
namespace for a particular pattern/behavior; literals can be used at any point within
the pattern, but if they come B<after> parameters with defaults within the URL, the
defaults for those parameters are less useful (as the parameters must always be
explicitly expressed in the path in order for the path to match the given, since the literals
must all be present).

  $obj->pattern( 'root/:controller/:action' );
  $obj->defaults( { action => 'list', } );
  # get controller 'test' action 'list'
  $obj->parse_path( 'root/test' );
  
  # get path 'root/cow/moo'
  $obj->generate_path( controller => 'cow', action => 'moo' );
  
  # and, to illustrate the issue of literals and optional parameters... (keeping the same defaults)
  $obj->pattern( ':action/root/:controller' );
  # get path 'bar/root/foo'
  $obj->generate_path( controller => 'foo', action => 'bar', );
  
  # get path 'list/root/item'; though 'list' is the default action, the literal segment 'root'
  # requires that the action be fully expressed.
  $obj->generate_path( controller => 'item' );

Each IC::Controller::Route::Object instance knows what combination of parameters it
is capable of expressing; it will only parse paths that it understands, and it will only
generate paths given a set of parameters that it can express.  When given a URL it does
not match, or when given a set of parameters that it cannot express within path generation,
it will return undef.

For more RESTful goodness, the B<method> attribute can be used to limit a particular
object to handling URL requests of the specified method type ('get', 'post', etc.).  Thus,
the exact same pattern could result in alternate behaviors depending on the HTTP request
type, which more-easily facilitates RESTful design.  If a "get" is thought of as a read
and a "post" as a write, then multiple routes can be set up to dispatch the same URL to
alternate actions within a controller, such that each action can assume the correct
request type and not concern itself with such things internally, and removing one of the
annoying impediments to RESTful design.

  $read = IC::Controller::Route::Object->new(
      pattern => ':controller/:id',
	  controllers => \@known_controller_names,
	  method => 'get',
	  action => 'show_by_id',
  );
  
  $write = IC::Controller::Route::Object->new(
      pattern     => ':controller/:id',
	  controllers => \@known_controller_names,
	  method      => 'post',
	  action      => 'edit_by_id',
  );

  # controller 'product' action 'show_by_id' id 'foo'
  $read->parse_path( 'product/foo', ); # 'get' is the default request method
  
  # undefined!
  $read->parse_path( 'product/foo', 'post' );
  
  # also undefined! (again, 'get' is the default method type)
  $write->parse_path( 'product/foo', );
  
  # controller 'product' action 'edit_by_id' id 'foo'
  $write->parse_path( 'product/foo', 'post' );

URL generation adheres to these rules as well; generate_path() assumes a method of 'get'
if none is specified.  The URL resulting cannot literally state is request type, so it
is up to the user of the object to ensure that paths are used appropriately according to
method type.

=head1 ATTRIBUTES

Attributes are Moose-style, meaning each accessor method is a get/set function.  There are
in fact more attributes than those listed here, but these should be considered "public"; use
of non-documented attributes is not supported and not encouraged.

=over

=item B<pattern>

The URL pattern to match when parsing, or to follow when generating URL.  The patterns
are broken down into path segments, splitting on '/'.  As such, paths are not able to
express parameters that contain forward slashes.

A pattern may consist of literal segments, which do not map to any corresponding parameter
and must appear literally as stated in the pattern, parameter segments which are identified
by a starting colon (e.g. ':param_name'), and array segments identified by a starting
asterisk ('*arrayname').

When parsing a URL/path, segments of the path mapping to parameters or an array will appear
as the value of the corresponding parameter/array within the resulting hashref.  Similarly,
when generating a URL/path, segments mapping to parameters will be replaced in the resulting
path by the value of the respective parameter as provided by the method caller.

Array-style parameters are greedy, eating whatever remains in the path.  As such, they
are only usable as the final segment of the path.  Because IC::Controller::Route::Object
is lazy, only building out the path-building/parsing data structures from a pattern when
necessary, violating this rule within the pattern will not throw an exception when first
setting the pattern.  However, an exception will be thrown if the pattern is used by
parsing, generation, etc.

=item B<controllers>

An arrayref listing all the controllers to which this particular object can theoretically
apply.  The ':controller' path segment within the B<pattern> attribute cannot match
controllers that do not appear in this list, so it is critical that this list be set
appropriately.

=item B<controller>

The controller to which this particular object applies; if set, this overrides any
default controller specified in B<defaults>, and any use of ':controller' in the B<pattern>
attribute must simply match the controller named here.

=item B<action>

The action to which this particular object applies; if set, it overrides any default
action specified in B<defaults> when parsing paths, and any use of ':action' in the B<pattern>
must match the attribute named here.  When generating paths, a match will only occur if
the action is specified in the parameters to B<generate_path()> matches the value set in
this attribute, or if no action parameter is provided but the same action value is specified
in the B<defaults> hash attribute.

=item B<defaults>

A hashref identifying the various default parameter values to use both for URL parsing
and generation.  Specifying defaults for parameters expressed within the B<pattern>
attribute can effectively make these path segments optional (see the USAGE section for
in-depth discussion and examples).  When generating paths, parameters not provided by
the caller can use the corresponding defaults as substitutes in the URL generation
process.

=item B<method>

The HTTP request method to which this pattern applies; undefined by default, objects
will ordinarily handle any request method type.  However, by specifying 'get', 'post', etc.,
an object can be further restricted to the type of method it will handle.  This is
done to allow for more RESTful design.

=back

=cut

has pattern => ( is => 'rw', );
has controllers => ( is => 'rw', );# isa => 'Ary', );
has method => ( is => 'rw', );
has controller => ( is => 'rw', );
has action => ( is => 'rw', );
has defaults => ( is => 'rw',); # isa => 'Hsh', );
has component_separator => (
	is => 'rw',
	default => sub {
		return qr{[./]+};
	},
);

has components => (
	is => 'rw',
#	isa => 'Ary',
#	default => sub {
#		my $self = shift;
#		return $self->build_components;
#	}
);

around components => sub {
	my $code = shift;
	my $self = shift;
	return $self->$code( @_ )
		if @_
	;
	my $result = $self->$code;
	$result = $self->$code( $self->build_components )
		if ! defined $result
	;
	return $result;
};

my $wrapper_sub = sub {
	my $code = shift;
	my $self = shift;
	my $result = $self->$code( @_ );
	if ( @_ ) {
		$self->components( undef );
	}
	return $result;
};

around $_ => $wrapper_sub
	for qw(
		pattern
		controllers
		defaults
		action
	)
;

around new => sub {
	my $code = shift;
	my $self = shift;
	my %params = @_;
	return $code->($self, %params);
};

my ($REGEX, $NAME, $LITERAL, $ARRAY, $DEFAULT, ) = (0..4);

my $has_default = sub {
	my $component = shift;
	return @$component > $DEFAULT;
};

=pod

=head1 METHODS

=over

=item B<build_components()>

This method causes the object to reconstruct its internal list of path components
and their corresponding defaults, types, etc.  This path component list is used
internally to facilitate path parsing and path generation.  While the object interface
is designed to minimize the need for public use of this function, certain things
may necessitate it; for instance, changing the internal state of the object's B<defaults>
hash is not something the object can detect; therefore, doing so necessitates that
B<build_components()> be called to refresh the internal path component list.

=item B<parse_path( $url [, $method ] )>

Will attempt to parse $url according to the B<pattern> and B<defaults>; if $url matches
the pattern appropriately, a hashref will be returned with parameters populated according
to the defaults and the information extracted from the $url according to the pattern.  If
$url does not match, will return undef.

The optional $method specifies the HTTP request method type ('get', 'post', etc.); defaults
to 'get'.

Because IC::Controller::Route::Object is intended for use within an MVC environment
in which everything is done by controllers and actions, $url will only be considered
valid for the current object if the parsing thereof results in both a controller and an
action parameter; URLs that match the pattern but fail to result in a controller/action
combination will be considered invalid and result in an undef.

=item B<generate_path( %parameters_list )>

Will inspect the %parameters_list and determine if the object is capable of expressing
the given set of parameters within a URL; if so, that URL will be generated and returned;
otherwise, undef is returned.

Because IC::Controller::Route::Object is intended for use within an MVC environment
in which everything is done by controllers and actions, %parameters_list B<must> specify
the desired controller and action.

The HTTP request method can be specified via the $parameters_list{method}; it defaults
to 'get' if not specified.  The path will be undefined if the object's B<method> attribute
is set to a defined value other than the method requested.

=back

=cut

sub build_components {
	my $self = shift;
	my $pattern = $self->pattern;
	return unless defined $pattern;

	my @path_components = split $self->component_separator, $pattern;
	my (@components, %defaults);
	%defaults = %{ $self->defaults || {} };
	$defaults{controller} = $self->controller
		if defined $self->controller
	;
	$defaults{action} = $self->action
		if defined $self->action
	;
	while (@path_components) {
		my $path = shift @path_components;
		my @component;
		if ($path =~ /^:(\w+)/) {
			# named parameter
			$component[$NAME] = $1;
			my $regex;
			if ($component[$NAME] eq 'controller') {
				my @list;
				if (defined $self->controller and length $self->controller) {
					@list = ($self->controller);
				}
				else {
					@list = @{ $self->controllers };
				}
				$regex = join('|', @list);
			}
			else {
				$regex = '.+';
			}
			$component[$REGEX] = qr{^$regex$};
			$component[$DEFAULT] = $defaults{ $component[$NAME] }
				if exists $defaults{ $component[$NAME] }
			;
		}
		elsif ($path =~ /^\*(\w+)/) {
			# named array parameter (eats up rest of path); no regex necessary
			confess 'Array-style parameter must be final component in path pattern!'
				if @path_components
			;
			$component[$REGEX] = undef;
			$component[$NAME] = $1;
			$component[$ARRAY] = 1;
			$component[$DEFAULT] = $defaults{ $component[$NAME] }
				if exists $defaults{ $component[$NAME] }
			;
			$component[$DEFAULT] = [] unless defined $component[$DEFAULT];
			my $ref = ref($component[$DEFAULT]);
			if (! $ref) {
				$component[$DEFAULT] = [ $component[$DEFAULT] ];
			}
			elsif ($ref ne 'ARRAY') {
				confess 'Only simple scalars and arrayrefs are permitted for array components!';
			}
		}
		else {
			# literal segment (no parameter associated); leave name and others undefined
			$component[$REGEX] = qr{^$path$};
			$component[$LITERAL] = $path;
		}
		if (defined $component[$NAME]) {
			$component[$DEFAULT] = $defaults{ $component[$NAME] }
				if exists $defaults{ $component[$NAME] }
			;
		}
		push @components, \@component;
	}
#printf STDERR "build_components: path '%s' generates structure:\n%s\n\n", $pattern, Dumper(\@components);
	return \@components;
}

sub parse_path {
	my $self = shift;
	my $path = shift;
	my $method = shift;
	$method = 'get' unless defined $method;
	return undef
		if $self->method
			and $self->method !~ /^$method$/i
	;

	my @segments = split $self->component_separator, $path;
	my (%params, $error, $array_seen,);
	%params = %{ $self->defaults || {} };

	$params{controller} = $self->controller
		if defined $self->controller and length $self->controller
	;

	$params{action} = $self->action
		if defined $self->action and length $self->action
	;

	my @components = @{ $self->components };
#printf STDERR "parse_path: path '%s' (method: '%s')\n\tsegments %s\n\tcomponents %s\n", $path, $method, Dumper(\@segments), Dumper(\@components);
	while (@segments and @components) {
		my $segment = shift @segments;
#printf STDERR "parse_path: considering segment '%s'\n", $segment;
		$error++ && last
			if ! (defined $segment and length $segment);

		my $component = shift @components;
		if (defined $component->[$REGEX]) {
			++$error && last unless $segment =~ /$component->[$REGEX]/;
			next if defined $component->[$LITERAL];
			$params{$component->[$NAME]} = $segment
				if defined $component->[$NAME]
			;
		}
		elsif ($component->[$ARRAY]) {
			++$error && last unless defined $component->[$NAME];
			my $target = $params{ $component->[$NAME] } = [];
			@$target = ($segment, @segments);
            @segments = ();
			$array_seen++;
			last;
		}
		else {
			$error++;
			last;
		}
	}
#printf STDERR "parse_path: exiting, error flag '%s' and params %s\n", ($error || ''), Dumper(\%params);
	$error ||= scalar( grep { $_->[$LITERAL] or ! $_->[$ARRAY] && ! $has_default->($_) } @components)
		if @components
	;
    $error ||= @segments;
	return undef if $error;
	return undef
		unless defined $params{controller} and defined $params{action}
	;
	# At this point we know we're good with the response; we just need to ensure
	# that any array component at the end of the path has a corresponding arrayref
	# in the params (if there's no default for it; we still want the structure to be there).
	if (! $array_seen and @components and $components[$#components]->[$ARRAY]) {
		my $component = pop @components;
		$params{ $component->[$NAME] } = $component->[$DEFAULT];
	}
	return \%params;
}

sub generate_path {
	my $self = shift;
	my %options = @_;

	my $controller = $options{controller};
	confess 'Controller must be specified for generate_path()'
		unless defined $controller and length $controller
	;

	my $defaults = { %{$self->defaults || {}} };
	$defaults->{controller}
		= $self->controller
		if defined $self->controller
			and length $self->controller
	;

	my $action = $options{action};
    $action = $defaults->{action}
        if !(defined($action) and length($action))
    ;
    return undef if defined $self->action
        and length($self->action)
        and (
            not defined($action)
            or ! length($action)
            or $action ne $self->action
        )
    ;
	$defaults->{action} = $self->action
		if defined $self->action
			and length $self->action
	;
	confess 'Action must be specified for generate_path()'
		unless defined $action && length $action
			or defined $defaults->{action} && length $defaults->{action}
	;

	if (defined $self->controller) {
		return undef if $self->controller ne $controller;
	}
	else {
		return undef unless grep { $_ eq $controller } @{ $self->controllers };
	}

	my $method = delete $options{method} || 'get';
	
	return undef
		if $self->method
			and $self->method !~ /^$method$/i
	;

	my (%known_params, %with_defaults, @components);
	@components = @{ $self->components || [] };

	%known_params
		= map {
			$with_defaults{$_->[$NAME]}++
				if $has_default->($_) || $_->[$ARRAY]
			;
			($_->[$NAME] => 1);
		}
		grep {
			! $_->[$LITERAL];
		}
		@components
	;

	delete @$defaults{keys %known_params};
#printf STDERR "generate_path: considering known parameters versus options;known params %s\ndefaults %s\noptions %s\n\n", Dumper(\%known_params), Dumper(\%with_defaults), Dumper(\%options);
	# undef if the options cannot be expressed with this path
	return undef
		if grep {
			! ( exists $known_params{$_} or exists $defaults->{$_} );
		}
		keys %options
	;
#print STDERR "generate_path: considering required parameters versus options and defaults\n";
	#undef if the known params are not adequately provided between params and defaults
	return undef
		if grep {
			! (
				defined($options{$_}) && length($options{$_})
				or $with_defaults{$_}
				or exists $defaults->{$_}
			);
		}
		keys %known_params
	;

#printf STDERR "generate_path: up to component processing for controller '%s' options %s\n", $controller, Dumper(\%options);
	my ($error, @segments);

	# Inspect from end of list to beginning; pop off any components that do not
	# need to be literally expressed in the path (due to defaults)
	while (@components) {
		my $component = $components[$#components];
#printf STDERR "generate_path: considering for removal: %s\n", Dumper($component);
		last if defined $component->[$LITERAL]
			or ! $has_default->( $component )
		;
		my $option = $options{$component->[$NAME]};
#printf STDERR "generate_path: option '%s'\n", $option;
		if (defined $option and length $option) {
			my $default = $component->[$DEFAULT];
			if ($component->[$ARRAY]) {
				$default = join '/', @$default;
				$option = join '/', @$option
					if ref $option eq 'ARRAY'
				;
			}
			$default = '' if ! defined $default;
#printf STDERR "generate_path: option '%s' default '%s'\n", $option, $default;
			last if $default ne $option;
		}
		# At this point, we know the component's default will be used and therefore
		# does not need to be literally expressed in the path
#printf STDERR "generate_path: popping component %s\n", Dumper($component);
		pop @components;
	}
#printf STDERR "generate_path: past default component removal; all remaining components must be provided\n";
	for my $component ( @components ) {
#printf STDERR "generate_path: checking component %s\n", Dumper($component);
		my @values;
		if (defined $component->[$NAME]) {
#printf STDERR "generate_path: component has name %s\n", $component->[$NAME];
			my $option = $options{ $component->[$NAME] };
			$option = $component->[$DEFAULT]
				if ! (defined($option) and length($option))
			;

			if (! (defined $option and length $option)) {
#printf STDERR "generate_path: option for component is undefined.\n";
				$error++; # unless $has_default->($component) or $component->[$ARRAY];
				last;
			}
			
			if ($component->[$ARRAY]) {
#printf STDERR "generate_path: component is an array\n";
				if (ref $option eq 'ARRAY') {
					@values = @$option;
				}
				else {
					@values = ($option);
				}
			}
			else {
#printf STDERR "generate_path: component is simple, setting value to %s\n", $option;
				@values = ($option);
			}
		}
		else {
#printf STDERR "generate_path: component is literal '%s'\n", $component->[$LITERAL];
			@values = ($component->[$LITERAL]);
		}
		push @segments, @values;
	}
#printf STDERR "generate_path: exiting, error flag '%s' and segments: %s", ($error || ''), Dumper(\@segments);
	return undef if $error;
	return join '/', @segments;
}

1;

__END__
