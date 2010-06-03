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

class_has '+_list_paging_provider'      => ( default => 'server' );

no Moose;
no MooseX::ClassAttribute;

my $_role_class            = __PACKAGE__->_root_model_class() . '::Role';
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

    my $user_roles = $_role_class->new( code => 'user' )->load->roles_using;

    my $role_options = [];
    for my $element (sort { $a->code cmp $b->code } @$user_roles) {
        push @$role_options, { 
            value    => $element->id,
            selected => ((defined $values->{role_id} and $values->{role_id} == $element->id) ? ' selected="selected"' : ''),
            display  => $element->code,
        };
    }

    $args->{context}->{include_options}->{roles} = $role_options;

    return;
}

sub _properties_action_hook {
    my $self = shift;
    my $args = { @_ };

    unless (defined $args->{db} and $args->{db} ne '') {
        IC::Exception->throw( '_properties_action_hook: Missing required argument: db' );
    }

    $self->SUPER::_properties_action_hook(@_);

    my $params = $self->_controller->parameters;

    my @required_fields = qw( role_id );
    if ($params->{_properties_mode} eq 'add') {
        push @required_fields, qw( new_password con_password );

        #
        # TODO: handle this appropriately
        #
        $params->{version_id} ||= 1;
    }

    for my $field (@required_fields) {
        unless (defined $params->{$field} and $params->{$field} ne '') {
            IC::Exception->throw( "Missing required value for '$field'" );
        }
    }

    if (defined $params->{new_password} and $params->{new_password} ne '' and $params->{new_password} ne $params->{con_password}) {
        IC::Exception->throw( q{Passwords don't match.} );
    }

    #
    # TODO: handle this in the interface
    #
    $params->{password_failure_attempts} ||= 0;

    if (defined $params->{new_password} and $params->{new_password} ne '') {
        unless (defined $params->{password_hash_kind_code} and $params->{password_hash_kind_code} ne '') {
            IC::Exception->throw( 'Missing required value for password hash kind' );
        }
        
        $params->{password} = IC::M::User->hash_password( $params->{new_password}, $params->{password_hash_kind_code} );

        delete @{$params}{qw( new_password con_password )};
    }

    my $role;
    if ($params->{role_id} eq '_new') {
        $role = $_role_class->new(
            db            => $args->{db},
            code          => "user_$params->{username}",
            display_label => "User: $params->{username}",
            description   => '',
            has_roles     => [
                {
                    code => 'user',
                },
            ],
        );
        $role->save;

        $params->{role_id} = $role->id;
        warn "params: $params->{role_id}\n";
    }
    else {
        $role = $_role_class->new(
            db => $args->{db},
            id => $params->{role_id},
        );
        unless ($role->load( speculative => 1 )) {
            IC::Exception->throw( "_properties_action_hook: Unrecognized role: $params->{role_id}" );
        }
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
