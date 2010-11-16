package IC::Manage;

use strict;
use warnings;

use JSON ();

use IC::Exceptions;
use IC::M::ManageClass;

use Moose;
use MooseX::ClassAttribute;

class_has '_class'                     => ( is => 'ro', default => undef );
class_has '_root_model_class'          => ( is => 'ro', default => 'IC::M' );
class_has '_model_class'               => ( is => 'ro', default => undef );
# TODO: can this be set based on _model_class?
class_has '_model_class_mgr'           => ( is => 'ro', default => undef );
class_has '_model_display_name'        => ( is => 'ro', default => undef );
class_has '_model_display_name_plural' => ( is => 'ro', default => undef );
class_has '_field_adjustments'         => ( is => 'ro', default => undef );
class_has '_role_class'                => ( is => 'ro', default => 'IC::M::Role' );

# order matters here, by making "DetailView" the first in this list
# it then becomes the default unless an override of _record_actions
# happens
class_has '_default_record_actions'    => ( is => 'ro', default => sub { [ qw( DetailView Drop ) ] } );

has '_controller'            => ( is => 'rw', required => 1 );
has '_ui_meta_struct'        => ( is => 'rw', default => sub { {} } );

#
# TODO: I don't particularly like this but without a way to pass them through
#       inner() I'm not sure how else to go about it, we could have made a Record
#       ManageRole but then we'd need a model object (aka DB row) for every class
#       that wants to use it which seems silly cause that is basically all of them
#
class_has '_object_ui_meta_struct' => ( is => 'rw', default => sub { {} } );
class_has '_model_object'          => ( is => 'rw', default => undef );

#
# TODO: the following groups still need to be factored
#

# TODO: should these four be included with a ManageRole?
class_has '_icon_path'                 => ( is => 'ro', default => '/ic/images/icons/file.png' );
class_has '_file_class'                => ( is => 'ro', default => 'IC::M::File' );
class_has '_file_resource_class'       => ( is => 'ro', default => 'IC::M::FileResource' );
class_has '_file_resource_class_mgr'   => ( is => 'ro', default => 'IC::M::FileResource::Manager' );

# TODO: include these in a ManageRole role? perhaps brought in if using the model mixin?
class_has '_upload_target_directory'   => ( is => 'ro', default => undef );
class_has '_upload_requires_object'    => ( is => 'ro', default => undef );

# TODO: make these a ManageRole?
class_has '_parent_manage_class'       => ( is => 'ro', default => undef );
class_has '_parent_model_link_field'   => ( is => 'ro', default => undef );

sub ui_meta_struct {
    #warn "IC::Manage::ui_meta_struct";
    my $self = shift;
    my $args = { @_ };

    my $struct = {};
    if (ref $self) {
        $struct = $self->_ui_meta_struct;
        $struct->{+__PACKAGE__} = 1;
        $struct->{_prototype} = $self->_prototype;

        my $inner_result = inner();

        $struct = $inner_result if defined $inner_result;
    }
    else {
        $self->_class_ui_meta_struct($struct, @_);
    }

    my $formatted = $struct;
    if (! defined $args->{format}) {
        return $formatted;
    }
    elsif ($args->{format} eq 'json') {
        return JSON::encode_json($formatted);
    }
    else {
        IC::Exception->throw("Unrecognized struct format: '$args->{format}'");
    }

    return;
};

sub _class_ui_meta_struct {
    #warn "IC::Manage::_class_ui_meta_struct";
    my $class = shift;
    my $struct = shift;
    my $args  = { @_ };

    unless (defined $class->_class) {
        IC::Exception->throw("Sub class has not overridden _class: $class");
    }

    my $class_model_obj = $class->get_class_model_obj;

    my $action_models = $class_model_obj->find_actions(
        query => [
            is_primary => 1,
        ],
    );

    my $actions = {};
    for my $action_model (@$action_models) {
        my $action_class = $action_model->load_lib;
        my $action       = $action_class->new(
            _controller => $args->{_controller},
        );

        $actions->{$action_model->code} = $action->ui_meta_struct;
    }

    $struct->{_class}            = $class->_class;
    $struct->{model_name}        = $class->_model_display_name;
    $struct->{model_name_plural} = $class->_model_display_name_plural;
    $struct->{actions}           = $actions;

    return $struct;
}

sub object_ui_meta_struct {
    #warn "IC::Manage::object_ui_meta_struct";
    my $class = shift;
    my $args = { @_ };

    unless (defined $class->_model_object) {
        $class->_model_object( $class->object_from_pk_params( $args->{_controller}->parameters ) )
    }

    my $model_object = $class->_model_object;

    my $struct = $class->_object_ui_meta_struct;
    $struct->{+__PACKAGE__} = 1;
    $struct->{description}  = $model_object->manage_description;

    my @actions = $class->_record_actions($model_object);
    for my $action (@actions) {
        $struct->{actions}->{$action} = {};
    }

    my $inner_result = inner();
    $struct = $inner_result if defined $inner_result;

    #
    # post process the list of actions provided by the sub class
    #
    # post processing will set the label and meta information in
    # the case that they aren't already defined
    #
    if (defined $struct->{actions}) {
        push @actions, keys %{ $struct->{actions} };
    }

    my $class_model_obj = $class->get_class_model_obj;

    my $action_models = $class_model_obj->find_actions(
        query => [
            is_primary => 0,
            code       => \@actions,
        ],
    );

    for my $action_model (@$action_models) {
        my $action_class = $action_model->load_lib;
        my $action       = $action_class->new(
            _controller => $args->{_controller},
        );

        my $action_ref = $struct->{actions}->{ $action_model->code } ||= {};
        unless (defined $action_ref->{label}) {
            $action_ref->{label} = $action_model->display_label; 
        }
        unless (defined $action_ref->{meta}) {
            $action_ref->{meta} = $action->ui_meta_struct; 
        }
    }

    my $formatted = $struct;
    if (! defined $args->{format}) {
        return $formatted;
    }
    elsif ($args->{format} eq 'json') {
        return JSON::encode_json($formatted);
    }
    else {
        IC::Exception->throw("Unrecognized struct format: '$args->{format}'");
    }

    return;
}

no Moose;
no MooseX::ClassAttribute;

sub get_class_model_obj {
    my $class = shift;

    my $class_obj = IC::M::ManageClass->new(
        code => $class->_class,
    );
    unless ($class_obj->load( speculative => 1 )) {
        IC::Exception->throw('Unrecognized class: ' . $class->_class);
    }

    return $class_obj;
}

sub load_class {
    my $self = shift;
    my $_class = shift;
    my $_subclass = shift;
      
    my $model_class = 'IC::M::ManageClass';
    my %model_args;
    if (defined $_subclass) {
        $model_class .= '::Action';

        %model_args = (
            class_code => $_class,
            code       => $_subclass,
        );
    }
    else {
        %model_args = (
            code => $_class,
        );
    }

    my $model = $model_class->new(%model_args);
    unless ($model->load( speculative => 1 )) {
        IC::Exception->throw("Can't load $model_class model object: $_class ($_subclass)");
    }

    my $class = $model->load_lib;

    return wantarray ? ($class, $model) : [ $class, $model ];
}

sub object_from_pk_params {
    my $self = shift;
    my $params = shift;

    my $_model_class = $self->_model_class;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    for my $_pk_field (@_pk_fields) {
        unless (defined $params->{$_pk_field}) {
            IC::Exception::MissingValue->throw( "PK argument ($_pk_field): Unable to retrieve object" );
        }
    }

    my %object_params = map { $_ => $params->{"_pk_$_"} } @pk_fields;

    my $object = $_model_class->new( %object_params );
    unless (defined $object) {
        IC::Exception::ModelInstantiateFailure->throw( $self->_model_display_name );
    }
    unless ($object->load(speculative => 1)) {
        IC::Exception::ModelLoadFailure->throw( 'Unrecognized ' . $self->_model_display_name . ': ' . (join ' => ', %object_params) );
    }

    return $object;
}

#
# given a manage class action code (name) determine whether a given or derived role
# has access rights to execute the function
#
sub check_priv {
    my $self = shift;
    my $check_action_name = shift;
    my $args = { @_ };

    my $check_role;
    if (defined $args->{role} and $args->{role}->isa($self->_role_class)) {
        $check_role = $args->{role};
    }
    elsif (defined $self->_controller->role) {
        $check_role = $self->_controller->role;
    }
    else {
        my ($package, $filename, $line) = caller(1);
        warn "$package called check_priv() but was unable to determine 'role' properties at line $line\n";
        return '';
    }

    # TODO: I'm not wild about this
    my ($class, $model) = $self->load_class($self->_class, $check_action_name);

    return ($check_role->check_right( 'execute' => $model ) ? 1 : 0);
}

#
# takes a set of named args, specifically a list of fields that we want to display 
# in a common key/value pair manner and the object used to derive the values
#
sub _fields_to_kv_defs {
    my $self = shift;
    my $args = { @_ };

    #
    # return a hash keyed on the field name passed in with a value
    # that is the corresponding definition as a hashref
    #
    my $return = {};

    #
    # get the structure used to override default behaviour for the fields,
    # it is keyed by DB field name
    #
    my $adjustments = $self->_field_adjustments || {};

    for my $field (@{ $args->{fields} }) {
        my $field_name = $field->name;
        my $adjust     = $adjustments->{$field_name} || {};

        my $ref = $return->{$field_name} = {
            code => $field_name,
        };

        my $label;
        if (defined $adjust->{label}) {
            $label = $adjust->{label};
        }
        else {
            $label = join ' ', map { $_ eq 'id' ? 'ID' : ucfirst } split /_/, $field_name;
        }
        $ref->{label} = $label;

        if (defined $args->{object}) {
            my $value;

            if (defined $adjust->{value_mapping}) {
                my $alt_object = $args->{object};
                if (defined $adjust->{value_mapping}->{object_accessor}) {
                    my $alt_object_method = $adjust->{value_mapping}->{object_accessor};
                    $alt_object = $args->{object}->$alt_object_method;
                }

                if (defined $adjust->{value_mapping}->{value_accessor}) {
                    my $sub_method = $adjust->{value_mapping}->{value_accessor};
                    $value = $alt_object->$sub_method;
                }
                else {
                    $value = $alt_object->$field_name;
                }
            }
            else {
                if ($field->type eq 'date') {
                    $value = $args->{object}->$field_name( format => '%Y-%m-%d' );
                }
                else {
                    $value = $args->{object}->$field_name;
                }
            }

            # force stringification with a concat
            $ref->{value} = defined($value) ? $value . '' : '';
        }
        else {
            # TODO: add ability to pull default value using an adjustment sub
        }
    }

    return $return;
}

#
# takes a set of named args, specifically a list of fields that we want form 
# definitions for and an object that should be used for determining values
#
sub _fields_to_field_form_defs {
    my $self = shift;
    my $args = { @_ };

    $args->{values} ||= {};

    #
    # return a hash keyed on the field name passed in with a value
    # that is the corresponding form definition as a hashref
    #
    my $return = {};

    #
    # get the structure used to override default behaviour for the fields,
    # it is keyed by DB field name
    #
    my $adjustments = $self->_field_adjustments || {};

    for my $field (@{ $args->{fields} }) {
        my $field_name = $field->name;
        my $adjust     = $adjustments->{$field_name} || {};

        #
        # boilerplate fields by their nature are automatically handled, therefore they aren't
        # editable, so skip them
        #
        next if grep { $field_name eq $_ } keys %{ { $self->_model_class->boilerplate_columns } };

        #
        # in the case of a passed in object we know it is edit, so skip fields
        # that can't be edited, otherwise it is add and skip those that shouldn't
        # be used in an add
        #
        if (defined $args->{object}) {
            next if (defined $adjust->{is_editable} and not $adjust->{is_editable});

            if (ref $adjust->{is_editable} eq 'CODE') {
                next if not $adjust->{is_editable}->($self, $args->{object});
            }
        }
        else {
            next if (defined $adjust->{is_addable} and not $adjust->{is_addable});
        }

        #
        # by default we make single field PKs that are integers with the name 'id'
        # not be editable, this can be overridden by specifying an is_editable adjustment
        #
        next if (
            $field_name eq 'id' 
            and $field->is_primary_key_member
            and $field->type eq 'serial'
            and not defined $adjust->{can_edit} 
        );

        #
        # fields is an array to allow for multiple fields to make up a single value
        # for the database field, i.e. password resets are handled through two values
        # 'new' and 'confirmed' even though it gets saved to the DB as a single value
        #
        my $def = {
            controls => [],
        };
        $return->{$field_name} = $def;

        if (defined $adjust->{controls}) {
            $def->{controls} = $adjust->{controls};
        }
        else {
            # TODO: give date, time, datetime, timestamp multiple controls, or can be done with
            #       one field type that is rendered using multiple client side controls?

            # TODO: add auto handling of FK relationships when it is trivial to handle them
            my $name = $field_name;

            # this is irritating, and necessary because IC eats "id" parameters
            if ($field_name eq 'id') {
                $name = '_work_around_ic_id';
            }

            my $control_ref = {
                name => $name,
            };
            push @{ $def->{controls} }, $control_ref;

            # see if a value was provided, if so, maintain it
            if (defined $args->{values}->{$name}) {
                $control_ref->{value} = $args->{values}->{$name};
            }
            elsif (defined $args->{object}) {
                $control_ref->{value} = $args->{object}->$field_name();
            }

            if (defined $adjust->{field_type}) {
                $control_ref->{type} = $adjust->{field_type};
            }
            else {
                if ($field->type eq 'text') {
                    $control_ref->{type} = 'TextareaField';
                }
                elsif ($field->type eq 'boolean') {
                    # use our own wrapper class because gallery-form's choicefield doesn't
                    # allow for pre-selected value
                    $control_ref->{type} = 'Radio';
                }
                elsif ($field->type eq 'date') {
                    # TODO: does this imply a validator?
                    $control_ref->{type} = 'Calendar';

                    if (ref $control_ref->{value}) {
                        $control_ref->{value} = $control_ref->{value}->strftime('%Y-%m-%d');
                    }
                }
                elsif ($field->type eq 'time') {
                    # TODO: does this imply a validator?
                    $control_ref->{type} = 'Time';

                    if (ref $control_ref->{value}) {
                        $control_ref->{value} = $control_ref->{value}->format('%H:%M:%S');
                    }
                }
                elsif ($field->type eq 'timestamp') {
                    # TODO: does this imply a validator?
                    $control_ref->{type} = 'CalendarWithTime';
                }
                else {
                    $control_ref->{type} = 'TextField';
                }
            }

            # force stringification, can't do this with only objects because
            # to the JSON encoder an integer is encoded differently if it
            # hasn't been stringified too
            $control_ref->{value} = $control_ref->{value} . '';

            if (grep { $control_ref->{type} eq $_ } qw( Radio CheckboxField SelectField )) {
                if (defined $adjust->{get_choices}) {
                    $control_ref->{choices} = $adjust->{get_choices}->($self, $args->{object});
                }
                elsif (grep { $_ eq $control_ref->{type} } qw( Radio ) and $field->type eq 'boolean') {
                    # these choices take strings instead of 0/1 because gallery-form doesn't handle 0/1 well ATM
                    $control_ref->{choices} = [
                        {
                            value => 'true', #1,
                            label => 'Yes',
                            ($control_ref->{value} ? (checked => JSON::true()) : ()),
                        },
                        {
                            value => 'false', #0,
                            label => 'No',
                            (! $control_ref->{value} ? (checked => JSON::true()) : ()),
                        },
                    ];
                }
                else {
                    $control_ref->{choices} = [];
                }
            }
            if (defined $adjust->{client_validator}) {
                $control_ref->{validator} = $adjust->{client_validator};
            }
        }
    }

    return $return;
}

sub _record_actions {
    my $self = shift;
    my $object = shift;

    return (
        @{ $self->_default_record_actions },
        @{ $self->_custom_record_actions($object) },
    );
}

sub _custom_record_actions { [] }

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
