package IC::Manage::TimeZones;

use strict;
use warnings;

use IC::M::TimeZone;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::TimeZone' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::TimeZone::Manager' );
class_has '+_model_display_name'        => ( default => 'Time Zone' );
class_has '+_model_display_name_plural' => ( default => 'Time Zones' );
class_has '+_sub_prefix'                => ( default => 'zone' );
class_has '+_func_prefix'               => ( default => 'TimeZones_zone' );

no Moose;
no MooseX::ClassAttribute;

sub zoneList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
}

sub zoneAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub zoneProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub zoneDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub zoneDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

__END__
