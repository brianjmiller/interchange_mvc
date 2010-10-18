package IC::Manage::Users;

use strict;
use warnings;

use IC::M::User;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

my $_hash_kind_class        = __PACKAGE__->_root_model_class() . '::HashKind';
my $_hash_kind_class_mgr    = $_hash_kind_class . '::Manager';
my $_role_class             = __PACKAGE__->_root_model_class() . '::Role';
my $_user_status_class      = __PACKAGE__->_root_model_class() . '::UserStatus';
my $_user_status_class_mgr  = $_user_status_class . '::Manager';
my $_user_version_class     = __PACKAGE__->_root_model_class() . '::UserVersion';
my $_user_version_class_mgr = $_user_version_class . '::Manager';
my $_time_zone_class        = __PACKAGE__->_root_model_class() . '::TimeZone';
my $_time_zone_class_mgr    = $_time_zone_class . '::Manager';

class_has '+_class'                     => ( default => 'Users' );
class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::User' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::User::Manager' );
class_has '+_model_display_name'        => ( default => 'User' );
class_has '+_model_display_name_plural' => ( default => 'Users' );

class_has '+_field_adjustments'           => (
    default => sub {
        {
            role_id  => {
                field_type  => 'SelectField',
                get_choices => sub {
                    my $self = shift;

                    my $objects = $_role_class->new( code => 'user' )->load->roles_using;

                    my $options = [
                        {
                            value => '_new',
                            label => 'Create New',
                        },
                    ];
                    for my $obj (@$objects) {
                        push @$options, {
                            value => $obj->id . '',
                            label => $obj->code,
                        };
                    }

                    return $options;
                },
                value_builder => {
                    code => sub {
                        my $self = shift;
                        my $object = shift;

                        my $params = $self->_controller->parameters;

                        my $role;
                        if ($params->{role_id} eq '_new') {
                            $role = $_role_class->new(
                                db            => $object->db,
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
                        }
                        else {
                            $role = $_role_class->new(
                                db => $object->db,
                                id => $params->{role_id},
                            );
                            unless ($role->load( speculative => 1 )) {
                                IC::Exception->throw( "Can't build value for role_id: Unrecognized role: $params->{role_id}" );
                            }
                        }

                        return $role->id;
                    },
                },
            },
            version_id  => {
                field_type  => 'SelectField',
                get_choices => sub {
                    my $self = shift;

                    my $options = [];
                    for my $obj (@{ $_user_version_class_mgr->get_objects( sort_by => 'id' ) }) {
                        push @$options, {
                            value => $obj->id . '',
                            label => $obj->display_label,
                        };
                    }

                    return $options;
                },
            },
            status_code  => {
                field_type  => 'SelectField',
                get_choices => sub {
                    my $self = shift;

                    my $options = [];
                    for my $obj (@{ $_user_status_class_mgr->get_objects( sort_by => 'display_label' ) }) {
                        push @$options, {
                            value => $obj->code . '',
                            label => $obj->display_label,
                        };
                    }

                    return $options;
                },
            },
            email => {
                client_validator => 'email',
                server_validator => 'email',
            },
            password => {
                controls => [
                    {
                        label   => 'Hash Kind',
                        name    => 'password_hash_kind_code',
                        type    => 'SelectField',
                        choices => [
                            map {
                                {
                                    value => $_->code . '',
                                    label => $_->display_label,
                                };
                            } @{ $_hash_kind_class_mgr->get_objects( sort_by => 'display_label' ) },
                        ],
                    },
                    {
                        label => 'New',
                        name  => 'new_password',
                        type  => 'password',
                    },
                    {
                        label => 'Confirm',
                        name  => 'con_password',
                        type  => 'password',
                    },
                ],
                value_builder => {
                    code => sub {
                        my $self = shift;

                        my $params = $self->_controller->parameters;

                        unless (defined $params->{new_password} and defined $params->{con_password} and $params->{new_password} ne '') {
                            IC::Exception->throw('Password field missing.');
                        }
                        if ($params->{new_password} ne $params->{con_password}) {
                            IC::Exception->throw( q{Passwords don't match.} );
                        }

                        unless (defined $params->{password_hash_kind_code} and $params->{password_hash_kind_code} ne '') {
                            IC::Exception->throw('Missing required value for password hash kind.');
                        }

                        my $hashed_password = $self->_model_class->hash_password(
                            $params->{new_password},
                            $params->{password_hash_kind_code},
                        );
                        my $additional_updates = [
                            {
                                db_field => 'password_hash_kind_code',
                                value    => $params->{password_hash_kind_code},
                            },
                        ];

                        return $hashed_password, $additional_updates;
                    },
                },
            },
            password_hash_kind_code => {
                # editing a password hash can only be done when changing the password itself
                is_editable => 0,

                # password hash is added through the password field controls
                is_addable  => 0,
            },
            time_zone_code  => {
                field_type  => 'SelectField',
                get_choices => sub {
                    my $self = shift;

                    my $options = [];
                    for my $obj (@{ $_time_zone_class_mgr->get_objects( sort_by => 'code' ) }) {
                        push @$options, {
                            value => $obj->code . '',
                            label => $obj->code,
                        };
                    }

                    return $options;
                },
            },

            # TODO: remove this once the calendar is fixed for adds
            password_expires_on => {
                is_addable => 0,
            },
        };
    },
);

no Moose;
no MooseX::ClassAttribute;

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
