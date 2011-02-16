=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::Manage;

use strict;
use warnings;

use IC::M::Right;
use IC::Manage;

use IC::C::Manage::Widget::Menu;

use Moose;
extends 'IC::C';

has '+layout' => ( default => 'layouts/standard' );

has custom_js => (
    is      => 'rw',
    default => sub { {} },
);
has custom_css => (
    is      => 'rw',
    default => sub { {} },
);

no Moose;

# the application subclass should register itself as the provider of the 'manage' controller
#__PACKAGE__->registered_name('manage');

sub index {
    my $self = shift;

    # TODO: move this check into an 'around'
    return $self->forbid unless $self->check_right('access_site_mgmt');

    my $context = {};

    for my $method qw( custom_js custom_css ) {
        if (keys %{ $self->$method }) {
            $context->{$method} = $self->$method;
        }
    }

    $self->render(
        layout  => '',
        context => $context,
    );

    return;
}

#
# "action" here is a bit of a misnomer, it is really any function of a manage class/action
#
sub run_action_method {
    my $self = shift;

    return $self->forbid unless $self->check_right('access_site_mgmt');

    my $params = $self->parameters;

    my $_method = $params->{_method};
    unless (defined $_method and $_method ne '') {
        IC::Exception->throw(q{Can't run action method: none provided});
    }

    my $class;
    eval {
        ($class) = IC::Manage->load_class(
            $params->{_class},
            $params->{_subclass},
        );
    };
    if (my $e = Exception::Class->caught) {
        IC::Exception->throw("Can't run action method: can't load class ($params->{_class}:$params->{_subclass}) - $e (" . $e->trace . ')');
    }

    unless (defined $class) {
        IC::Exception->throw("Can't run action method: load_class returned nothing ($params->{_class}:$params->{_subclass})");
    }

    my $invokee;
    if (defined $params->{_subclass}) {
        # TODO: need to check privilege
        #my $function_obj = IC::M::ManageFunction->new( code => $function )->load;
        #unless ($self->check_right( 'execute', $function_obj )) {
            #IC::Exception->throw('Role ' . $self->role->display_label . " can't execute $function");
        #}

        eval {
            $invokee = $class->new();
        };
        if (my $e = Exception::Class->caught) {
            IC::Exception->throw("Can't instantiate manage class ($class): $e");
        }
    }
    else {
        # TODO: do we need to restrict privs on class method invocations?
        $invokee = $class;
    }

    unless (defined $invokee) {
        IC::Exception->throw("Can't run action method $_method: Unable to determine invokee ($params->{_class}:$params->{_subclass})"); 
    }

    my $result = eval {
        #
        # we use a hash reference here so that method modifiers
        # have a location where they can munge arguments that get
        # seen further down the processing chain
        #
        my $context = {
            controller => $self,
        };
        my $struct = $context->{struct} = {};

        $invokee->$_method(
            context => $context,
        );

        my $formatted;
        if (! defined $params->{_format}) {
            $formatted = $struct;
        }
        elsif ($params->{_format} eq 'json') {
            $formatted = JSON::encode_json($struct);
        }
        else {
            IC::Exception->throw("Unrecognized struct format: '$params->{_format}'");
        }

        my $response = $self->response;
        $response->headers->status('200 OK');
        $response->headers->content_type('text/plain');
        #$response->headers->content_type('application/json');
        $response->buffer( $formatted );
    };
    if (my $e = IC::Exception->caught()) {
        IC::Exception->throw("Failed manage method ($_method) execution (explicitly): $e (" . $e->trace . ')');
    }
    elsif ($@) {
        IC::Exception->throw("Failed manage method ($_method) execution: $@");
    }

    return;
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
