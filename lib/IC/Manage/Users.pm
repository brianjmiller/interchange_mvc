package IC::Manage::Users;

use strict;
use warnings;

use IC::M::User;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::User' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::User::Manager' );
class_has '+_model_display_name'        => ( default => 'User' );
class_has '+_model_display_name_plural' => ( default => 'Users' );
class_has '+_sub_prefix'                => ( default => 'user' );
class_has '+_func_prefix'               => ( default => 'Users_user' );
class_has '+_parent_manage_class'       => ( default => 'IC::Manage::Roles' );
class_has '+_parent_model_link_field'   => ( default => 'role' );

no Moose;
no MooseX::ClassAttribute;

my $_user_status_class     = __PACKAGE__->_root_model_class() . '::UserStatus';
my $_user_status_class_mgr = $_user_status_class . '::Manager';
my $_time_zone_class        = __PACKAGE__->_root_model_class() . '::TimeZone';
my $_time_zone_class_mgr    = $_time_zone_class . '::Manager';

sub userList {
    my $self = shift;
    return $self->_common_list(@_);
}

sub userAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub userProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $values = $args->{context}->{f};

    my $status_options = [];
    my $statuses = $_user_status_class_mgr->get_objects;
    for my $element (sort { $a->display_label cmp $b->display_label } @$statuses) {
        push @$status_options, { 
            value    => $element->code,
            selected => ((defined $values->{status_code} and $values->{status_code} eq $element->code) ? ' selected="selected"' : ''),
            display  => $element->display_label,
        };
    }

    $args->{context}->{include_options}->{statuses} = $status_options;

    my $time_zone_options = [];
    my $time_zones = $_time_zone_class_mgr->get_objects;
    for my $element (sort { $a->code cmp $b->code } @$time_zones) {
        push @$time_zone_options, { 
            value    => $element->code,
            selected => ((defined $values->{time_zone_code} and $values->{time_zone_code} eq $element->code) ? ' selected="selected"' : ''),
            display  => $element->code,
        };
    }

    $args->{context}->{include_options}->{time_zones} = $time_zone_options;

    return;
}

sub _properties_action_hook {
    my $self = shift;

    my $params = $self->_controller->parameters;

    if ($params->{_properties_mode} eq 'add') {
        for my $field qw(new_password con_password) {
            unless (defined $params->{$field} and $params->{$field} ne '') {
                IC::Exception->throw( "Missing required value for '$field'" );
            }
        }
    }
    if (defined $params->{new_password} and $params->{new_password} ne '' and $params->{new_password} ne $params->{con_password}) {
        IC::Exception->throw( q{Passwords don't match.} );
    }

    $params->{password_failure_attempts} ||= 0;

    if (defined $params->{new_password} and $params->{new_password} ne '') {
        $params->{password} = Digest::MD5::md5_hex( $params->{new_password} );
        delete @{$params}{qw( new_password con_password )};
    }

    return;
}

sub userDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub userDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

__END__
