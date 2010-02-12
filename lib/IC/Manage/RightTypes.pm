package IC::Manage::RightTypes;

use strict;
use warnings;

use IC::M::RightType;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::RightType' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::RightType::Manager' );
class_has '+_model_display_name'        => ( default => 'Right Type' );
class_has '+_model_display_name_plural' => ( default => 'Right Types' );
class_has '+_sub_prefix'                => ( default => 'type' );
class_has '+_func_prefix'               => ( default => 'RightTypes_type' );
class_has '+_list_cols'                 => (
    default => sub {
        [
            {
                display => 'Code',
                method  => 'code',
            },
            {
                display => 'Target Kind',
                method  => 'target_kind_code',
            },
            {
                display => 'Display Label',
                method  => 'display_label',
            },
            {
                display => 'Description',
                method  => 'description',
            },
        ],
    },
);

no Moose;
no MooseX::ClassAttribute;

sub typeList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
}

sub typeAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub typeProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $values = $args->{context}->{f};

    my $target_kind_options = [];
    my $target_kinds = IC::M::RightTypeTargetKind::Manager->get_objects( sort_by => 'display_label' );

    for my $element (@$target_kinds) {
        push @$target_kind_options, { 
            value    => $element->code,
            selected => ((defined $values->{target_kind_code} and $values->{target_kind_code} eq $element->code) ? ' selected="selected"' : ''),
            display  => $element->display_label,
        };
    }

    $args->{context}->{include_options}->{target_kinds} = $target_kind_options;

    return;
}

sub _properties_action_hook {
    my $self = shift;

    my $params = $self->_controller->parameters;

    # special case of empty string to NULL
    if ($params->{target_kind_code} eq '') {
        $params->{target_kind_code} = undef;
    }

    return;
}

sub typeDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub typeDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

__END__
