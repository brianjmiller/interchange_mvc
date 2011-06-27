package IC::C;

use strict;
use warnings;

use File::Spec ();

use IC::Config;
use IC::Exception;
use IC::M::Role;
use IC::M::Right;
use IC::M::RightType;
use IC::Component::HTMLHeader;
use IC::Component::HTMLFooter;

use Moose;
extends 'IC::Controller';

has 'layout' => (
    is      => 'rw',
    default => 'layouts/_common',
);
has 'context' => (
    is         => 'rw',
    isa        => 'HashRef',
    default    => sub { {} },
    auto_deref => 1,
);
has user => (
    is  => 'rw',
    isa => 'IC::M::User',
);
has role => (
    is  => 'rw',
    isa => 'IC::M::Role',
    trigger => sub { shift->_rights_cache( {} ) },
);
has 'build_header_component' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);
has 'html_header_component' => (
    is => 'rw',
    isa => 'Object',
);
has 'build_footer_component' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);
has 'html_footer_component' => (
    is => 'rw',
    isa => 'Object',
);

#
# because our header/footer could contain components
# that need to load their own styles, those
# components need to be rendered before the header
# is rendered, so to do so we pre-render the content
# of these two components and just stuff them into
# the layout as the last part of the render process
#
has 'html_header_content' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);
has 'html_footer_content' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'content_title' => (
    is => 'rw',
);
has 'content_subtitle' => (
    is => 'rw',
);
has 'additional_stylesheets' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has 'additional_js_libs' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has error_messages => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has status_messages => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has _right_type_cache => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    lazy    => 1,
);
has _rights_cache => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    lazy    => 1,
);
has _method_cache => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    lazy    => 1,
);
has role_graph => (
    is      => 'rw',
    default => sub {
        my $role = shift->role;
        $role ? IC::M::Role::Graph->new( db => $role->db ) : undef;
    },
    lazy    => 1,
);
after 'content_title' => sub {
    my $self = shift;

    return unless defined $_[0];
    return unless (defined $self->html_header_component and not defined $self->html_header_component->page_title);

    $self->html_header_component->page_title($_[0]);

    return;
};

__PACKAGE__->error_handler( 'handle_exception' );

=begin Comment

#
# TODO: would be nice to restore this for more general use
#

{
    my $method_cache = sub {
        my $orig = shift;
        my $self = shift;

        my $cache = $self->_method_cache;

        my $key = Scalar::Util::refaddr( $orig );
        $cache->{$key} = $self->$orig()
            unless exists $cache->{$key};

        return $cache->{$key};
    };

    sub cache_methods {
        my $pkg = shift;

        return unless @_;

        around @_ => $method_cache;

        return @_; 
    }
}

=end Comment

=cut

no Moose;

sub handle_exception {
    my ($self, $exception) = @_;

    my $logger = ref $self ? $self->logger : IC::Log->logger;
    $logger->error('Exception handler invoked for error: %s', Data::Dumper::Dumper($exception));
    if (UNIVERSAL::isa($exception->error, 'IC::Exception::LoginRequired')) {
        $self->session->{_login_form_redirect} = $ENV{REQUEST_URI};
        $self->redirect(
            controller  => 'user',
            action      => 'login_form',
            method      => 'get',
            secure      => 1,
            get         => {
                redirect => 1,
            },
        );
        return $self->response;
    }

    my $context = {
        (UNIVERSAL::isa($exception, 'IC::Exception')
            ? ( type => $exception->description, trace => $exception->trace )
            : ( type => 'Unknown', trace => '' )
        ),
        exception => $exception
    };

    my $response = IC::Controller::Response->new;
    $response->headers->status('500 Internal Server Error');
    $response->headers->content_type('text/html');
    $response->buffer(
        $self->render_local(
            layout  => $self->layout,
            view    => 'error.tst',
            context => $context,
        ),
    );

    return $response;
}

{
    my %anonymous_action;

    sub anonymous_actions {
        my $invocant = shift;

        my $registry = $anonymous_action{ $invocant->registered_name } ||= {};
        @$registry{ @_ } = (1) x @_;

        return scalar @_;
    }

    sub allows_anonymous_access {
        my ($invocant, $action) = @_;

        return unless my $registry = $anonymous_action{ $invocant->registered_name };

        return $registry->{$action};
    }
}

sub BUILD {
    my $self = shift;

    # TODO: this isn't safe because there is no assumption that a session
    #       must exist at this point, session is not set until request()
    #       is executed
    if (defined $self->session) {
        if (my $stack = $self->session->{login_stack}) {
            if (@$stack) {
                $self->user( IC::M::User->new( id => $stack->[$#$stack]->{user} )->load );
                $self->role( $self->user->role );
            }
        }
    }
    else {
        warn "session unavailable in controller BUILD() ($self)\n";
    }

    push @{ $self->view->base_paths }, File::Spec->catfile( IC::Config->adhoc_base_path, 'mvc', 'views' );

    if ($self->layout ne '') {
        $self->add_stylesheet(
            kind => 'ic',
            path => $self->layout . '.css',
        );
    }

    if (! defined $self->html_header_component and $self->build_header_component) {
        $self->html_header_component( IC::Component::HTMLHeader->new( controller => $self ) );
    }
    if (! defined $self->html_footer_component and $self->build_footer_component) {
        $self->html_footer_component( IC::Component::HTMLFooter->new( controller => $self ) );
    }

    return;
}

sub prepare_parameters {
    my $self = shift;
    my ($param) = @_;

    IC::Exception::LoginRequired->throw
        unless $self->role || $self->allows_anonymous_access( $param->{action} );

    return $self->SUPER::prepare_parameters($param);
}

sub render {
    my $self = shift;
    my %args = @_;

    #
    # this allows us to provide a common layout for all controllers
    # without symlinking them
    #
    unless (defined $args{layout}) {
        if ($self->layout ne '') {
            $args{layout} = $self->layout;
        }
    }

    #
    # order matters here, the footer has to have been rendered by the
    # time the header is, otherwise styles needed in the footer won't
    # be rendered by the header
    #
    if (defined $self->html_footer_component and ! defined $self->html_footer_content) {
        $self->html_footer_content( $self->html_footer_component->content );
    }
    if (defined $self->html_header_component and ! defined $self->html_header_content) {
        $self->html_header_content( $self->html_header_component->content );
    }

    return $self->SUPER::render(%args);
}

sub forbid {
    my $self = shift;

    $self->response->buffer( $self->render_local( view => 'forbidden' ) );
    $self->response->headers->status( '403 Forbidden' );

    return;
}

# TODO: is this deprecated by the anonymous action stuff?
#
# this is less than ideal cause it is going to force
# a call to be coded into every action that needs to
# check just to prevent it from being called when
# we must not check, which is rare
#
# can we use a meta property of the controller class
# to turn off when it should be called and then have
# the default be to call it? See MooseX::Attribute
# use in Manage classes
#
sub check_login {
    my $self = shift;

    unless (defined $self->role) {
        $self->redirect(
            controller => 'user',
            action     => 'login',
            secure     => 1,
        );
        return 1;
    }

    return;
}

#
# method for adding a stylesheet to our controller's
# stack of them, most importantly it checks for pre-
# existence of the requested stylesheet in the stack
# which prevents duplicated output -- one example
# is when a component has a stylesheet but that
# component exists more than once in the view
#
sub add_stylesheet {
    my $self = shift;
    my $args = { @_ };

    for my $element qw( kind path ) {
        unless (defined $args->{$element} and $args->{$element} ne '') {
            IC::Exception::ArgumentMissing->throw("Can't add stylesheet argument missing: $element");
        }
    }

    # now prevent duplicates
    my $found = 0;
    for my $element (@{ $self->additional_stylesheets }) {
        if ($element->{path} eq $args->{path} and $element->{kind} eq $args->{kind}) {
            $found = 1;
            last;
        }
    }

    unless ($found) {
        push @{ $self->additional_stylesheets }, $args;
    }

    return;
}

#
# method for adding a javascript lib to our controller's
# stack of them, most importantly it checks for pre-
# existence of the requested javascript lib in the stack
# which prevents duplicated output
#
sub add_js_lib {
    my $self = shift;
    my $args = { @_ };


    # 'kind' is optional, 'path' is required
    if (defined $args->{kind} and $args->{kind} eq '') {
        IC::Exception::ArgumentMissing->throw("Can't add javascript lib argument invalid: kind");
    }
    unless (defined $args->{path} and $args->{path} ne '') {
        IC::Exception::ArgumentMissing->throw("Can't add javascript lib argument missing: path");
    }

    # now prevent duplicates
    my $found = 0;
    for my $element (@{ $self->additional_js_libs }) {
        if ($element->{path} eq $args->{path} and
            (!defined($element->{kind}) or $element->{kind} eq $args->{kind})) {
            $found = 1;
            last;
        }
    }

    unless ($found) {
        push @{ $self->additional_js_libs }, $args;
    }

    return;
}

sub add_error_messages {
    my $self = shift;
    push @{ $self->error_messages }, @_;
    return scalar(@{ $self->error_messages });
}

sub add_status_messages {
    my $self = shift;
    push @{ $self->status_messages }, @_;
    return scalar(@{ $self->status_messages });
}

sub is_superuser {
    my $self = shift;
    return unless my $role = $self->role;

    my $cache = $self->_rights_cache;

    my $result = exists $cache->{superuser}
        ? $cache->{superuser}
        : ( $cache->{superuser} = $role->check_right( 'superuser', undef, $self->role_graph ) );

    return unless $result and @$result;
    return $result->[0];
}

sub is_valid_right_type {
    my $self = shift;
    my ($name, $target) = @_;

    my $target_name;
    if ($target) {
        my $check_target = ref $target eq 'ARRAY' ? $target->[0] : $target;
        $target_name = $check_target->rights_class->implements_type_target;
    }
    else {
        $target_name = '';
    }

    my $stash = $self->_right_type_cache->{$target_name};
    $stash->{$name} = IC::M::RightType->is_valid_type( $name, $target )
        if ! exists $stash->{$name};

    my $result = $stash->{$name};
    return $result if $result;

    return;
}

sub check_right {
    my $self = shift;
    my ($name, $target) = @_;

    my $role = $self->role;
    return unless $role;

    if (my $super = $self->is_superuser) {
        return unless $self->is_valid_right_type( $name, $target );

        return $target if ref $target eq 'ARRAY';

        return [ $super ];
    }

    return $role->check_right( $name, $target, $self->role_graph );
}

sub can_switch_to {
    my $self = shift;
    return unless $self->role;

    my $set = IC::M::User::Manager->get_objects(
        db    => $self->role->db,
        query => [
            #'!status_code' => 'disabled',
        ],
    );
    return unless $set and @$set;

    return $self->check_right( 'switch_user', $set );
}

#
# Check for Module::Refresh, if we have it and
# are in a camp then reload the modules during
# process initialization
#
{
    my $refresh_on = 0;
    eval 'use Module::Refresh';
    if ($@) {
        warn "Can't load Module::Refresh: $@\n";
    }
    else {
        if (IC::Config->camp) {
            warn "Turning on module refresh for process_initialization...\n";
            Module::Refresh->new();
            $refresh_on = 1;
        }
    }

    sub process_initialization {
        #warn "process_initialtization refresh value: $refresh_on\n";
        Module::Refresh->refresh if $refresh_on;
    }
}

1;

__END__

=pod

=head1 NAME

B<IC::C>: base controller class used for provided controllers

=head1 DESCRIPTION

All controller classes in the application within the B<IC::C::> space should inherit
from this class.  It derives from B<IC::Controller>, but adds a variety of templating 
and access control methods and attributes

=head1 ATTRIBUTES

=over

=item B<additional_js_libs>

Don't manipulate directly; use B<add_js_lib()>.

=item B<additional_stylesheets>

Don't manipulate directly; use B<add_stylesheet()>.

=item B<error_messages>

An arrayref of error messages to be displayed to the user in the resulting output.  The normal layout
associated with the base controller spits these out prominently.

It's generally advisable to manipulate this stack exclusively through the B<add_error_messages()> method.

=item B<role>

The B<IC::M::Role> instance associated with the logged-in state of the current request/session.
This is populated automatically when the controller is instantiated, though you could set it explicitly
if you really wanted.  Just don't, unless you're sure.

This is effectively the "user" of the application for the current request.

=item B<status_messages>

Like B<error_messages>, except for status notifications (like "Save successful", etc.) rather than
hard errors.  Also like errors, manipulate this through B<add_status_messages()> rather than directly.

=back

=head1 METHODS

Methods are grouped below by general functional area or problem domain.

=head2 ACCESS CONTROL

=over

=item I<anonymous_actions( @action_names )>

A class-level method to be invoked within a controller's definition, which registers all actions named in
I<@action_names> as allowing anonymous (non-logged-in) access.  The default is for all actions to require
valid login credentials/state.

If you have a controller class B<EndPoint::C::StupidIdeas> and you want to allow anonymous access to its
I<totally_unsafe> and I<completely_unwise> action methods, then you would want to do something like this:

 package EndPoint::C::StupidIdeas;
 use strict;
 use warnings;
 use Moose;
 extends qw(IC::C);
 ...

 __PACKAGE__->anonymous_actions(
     qw(
         completely_unwise
         totally_unsafe
     )
 );
 ...
 sub completely_unwise {
     my $self = shift;
     $self->render(
         view => 'show_them_everything',
         context => {
             data => EndPoint::M::CrownJewel->get_objects(),
         },
     );
     return
 }
 
 sub totally_unsafe {
     my $self = shift;
     EndPoint::M::WorkEntry->delete_objects();
     return $self->redirect( action => 'completely_unwise' );
 }
 ...

Now those actions on that controller will execute without requiring logged-in status.

This enforces a default-deny security policy for accessing any aspect of the application.  Yay.

=item I<can_switch_to()>

Returns an arrayref containing the B<IC::M::User> users to which the current role is allowed to
switch (via the "switch_user" right).

=item I<check_login()>

Checks for presence of B<role> attribute and, if undefined, issues a redirect to the login page.  A helper
function.

At some future date we'll make the class a bit more magical so it does login checks automatically and you
won't have to know about check_login.  Ah, the future.  It's great.  Everything is possible.

=item I<check_right( $name, $target )>

Essentially wraps B<IC::M::Right>->B<check_right()>.  See that method
for details about result values and semantics of checking rights on targets.  The return values and behaviors
of this method are the same, except that:

=over

=item *

You do not need to specify the role for which the right check is performed; the controller's current
B<role> attribute is used for that.

=item *

This method consults the B<is_superuser()> method and will grant any and all rights requested, so long as
the right requested corresponds to a valid B<IC::M::RightType>, should the current role have the
superuser privilege.

=back

In the event that the user is a superuser, and the invocation is such that you would get an
B<IC::M::Right> object as a result, you will receive the right object that grants superuser status.

=item I<is_superuser()>

If the active role (see B<role> attribute above) has the "superuser" right, that B<IC::M::Right> instance
is returned (so you can consult the right if you want, or simply use it as a truth value).

Otherwise returns false.

This is performed once per B<role> value; the result is cached in the controller instance and will be reused
until the controller is destroyed or the B<role> value is changed.  This reduces database demand, at the expense
of meaning the first check of I<is_superuser()> within a given request will determine superuser status for
the duration of the request, regardless of possible concurrent state changes in the underlying database.

=item I<is_valid_type( $name, $target )>

For a I<$name>/I<$target> pair with semantics identical to I<check_right>, determines if the name and
optional target(s) refer to a known right type, returning the B<IC::M::RightType> object if so.

Otherwise, false.

Results are cached per controller instance, to eliminate extraneous database checks within a given request.

This is largely intended as a helper function for I<check_right()>, but it's made public for convenience.

=back

=head2 TEMPLATING

=over

=item I<add_error_messages( @messages )>

Pushes arbitrary number of text I<@messages> onto the error message stack (see B<error_messages> attribute).

=item I<add_js_lib( %opt )>

Given a JavaScript library identifier in I<%opt>, pushes the library onto the stack of libraries to include
in the result output, checking for duplicates to ensure libraries are only included once.

The identifier is determined by the following in I<%opt>:

=over

=item kind

=item path

=back

=item I<add_status_messages( @messages )>

Pushes arbitrary number of text I<@messages> onto the status message stack (see B<status_messages> attribute).

=item I<add_stylesheet( %opt )>

Given a CSS module identifier, pushes the CSS module onto the stack of modules to include in the result output,
checking for duplicates along the way.

CSS modules are identified via I<%opt> with:

=over

=item kind

=item path

=back

=back

=head1 CREDITS

Blame is shared:

=over

=item *

Blame Brian for most of the templating.

=item *

Blame Ethan for most of the access control.

=back

A culture of blame is a great culture to be in.

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

