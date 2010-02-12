package IC::Manage::Rights;

use strict;
use warnings;

use IC::M::Right;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::Right' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::Right::Manager' );
class_has '+_model_display_name'        => ( default => 'Right' );
class_has '+_model_display_name_plural' => ( default => 'Rights' );
class_has '+_sub_prefix'                => ( default => 'right' );
class_has '+_func_prefix'               => ( default => 'Rights_right' );
class_has '+_parent_manage_class'       => ( default => 'IC::Manage::Roles' );
class_has '+_parent_model_link_field'   => ( default => 'role' );

no Moose;
no MooseX::ClassAttribute;

my $_right_type_class     = __PACKAGE__->_root_model_class() . '::RightType';
my $_right_type_class_mgr = $_right_type_class . '::Manager';

sub rightAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub rightProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $values = $args->{context}->{f};

    my $right_type_options = [];

    my $right_types = $_right_type_class_mgr->get_objects;
    for my $element (sort { $a->code cmp $b->code || $a->target_kind_code cmp $b->target_kind_code } @$right_types) {
        push @$right_type_options, { 
            value    => $element->id,
            selected => ((defined $values->{right_type_id} and $values->{right_type_id} eq $element->id) ? ' selected="selected"' : ''),
            display  => $element->manage_description,
        };
    }

    $args->{context}->{include_options}->{right_types} = $right_type_options;

    return;
}

sub rightDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub rightDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

__END__
