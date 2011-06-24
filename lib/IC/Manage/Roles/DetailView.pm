package IC::Manage::Roles::DetailView;

use strict;
use warnings;

use Moose;
extends 'IC::Manage::Roles';

augment 'ui_meta_struct' => sub {
    #warn "IC::Manage::Roles::DetailView::ui_meta_struct(augment)";
    my $self = shift;
    my %args = @_;

    my $object = $args{context}->{object};
    my $struct = $args{context}->{struct};

    $struct->{'IC::Manage::Roles::DetailView::ui_meta_struct(augment)'} = 1;

    my @tabs;

    my $has_roles_tab = $self->_has_roles_tab($object, $args{context}->{controller});
    push @tabs, $has_roles_tab if defined $has_roles_tab;

    my $has_users_tab = $self->_has_users_tab($object, $args{context}->{controller});
    push @tabs, $has_users_tab if defined $has_users_tab;

    my $roles_using_this_role_tab = $self->_roles_using_this_role_tab($object, $args{context}->{controller});
    push @tabs, $roles_using_this_role_tab if defined $roles_using_this_role_tab;

    my $rights_tab = $self->_rights_tab($object, $args{context}->{controller});
    push @tabs, $rights_tab if defined $rights_tab;

    if (@tabs) {
        splice @{ $struct->{config}->{data} }, 1, 0, @tabs;
    }

    inner();

    return;
};

# TODO: my hunch is that a new Moose wouldn't require us to make these separate,
#       and really the first shouldn't be necessary at all
with 'IC::ManageRole::Base';
with 'IC::ManageRole::DetailView';

no Moose;

sub _has_roles_tab {
    my $self = shift;
    my $object = shift;
    my $controller = shift;

    my $has_roles = $object->has_roles;
    return unless @$has_roles;

    my $tab = {
        label   => 'Has Roles',
        content => {
            type   => 'DataTable',
            config => {
                table_config => {
                    columnset => [
                        {
                            key   => 'index',
                            label => '#',
                        },
                        {
                            key   => 'description',
                            label => 'Description',
                        },
                    ],
                },
            },
        },
    };

    my $count = 1;
    for my $element (@$has_roles) {
        push @{ $tab->{content}->{config}->{table_config}->{recordset} }, {
            index       => $count,
            description => $element->manage_description,
        };
        $count++;
    }

    return $tab;
}

sub _has_users_tab {
    my $self = shift;
    my $object = shift;
    my $controller = shift;

    my $users = $object->users;
    return unless @$users;

    my $tab = {
        label   => 'Has Users',
        content => {
            type   => 'DataTable',
            config => {
                table_config => {
                    columnset => [
                        {
                            key   => 'index',
                            label => '#',
                        },
                        {
                            key   => 'description',
                            label => 'Description',
                        },
                    ],
                },
            },
        },
    };

    my $count = 1;
    for my $element (@$users) {
        push @{ $tab->{content}->{config}->{table_config}->{recordset} }, {
            index       => $count,
            description => $element->manage_description,
        };
        $count++;
    }

    return $tab;
}

sub _roles_using_this_role_tab {
    my $self = shift;
    my $object = shift;
    my $controller = shift;

    my $roles_using = $object->roles_using;
    return unless @$roles_using;

    my $tab = {
        label   => 'Roles Using this Role',
        content => {
            type   => 'DataTable',
            config => {
                table_config => {
                    columnset => [
                        {
                            key   => 'index',
                            label => '#',
                        },
                        {
                            key   => 'description',
                            label => 'Description',
                        },
                    ],
                },
            },
        },
    };

    my $count = 1;
    for my $element (@$roles_using) {
        push @{ $tab->{content}->{config}->{table_config}->{recordset} }, {
            index       => $count,
            description => $element->manage_description,
        };
        $count++;
    }

    return $tab;
}

sub _rights_tab {
    my $self = shift;
    my $object = shift;
    my $controller = shift;

    my $rights = $object->rights;
    return unless @$rights;

    my $tab = {
        label   => 'Rights',
        content => {
            type   => 'Grid',
            config => {
                units => [
                    [
                        {
                            percent => 50,
                            content => [
                                'Granted Rights',
                            ],
                        },
                        {
                            percent => 50,
                            content => [
                                'Denied Rights',
                            ],
                        },
                    ]
                ],
            },
        },
    };

    my %rights_by_grant;
    my %right_types;

    for my $right (@$rights) {
        if (! exists $right_types{$right->right_type_id}) {
            $right_types{$right->right_type_id} = {
                display_label    => $right->right_type->display_label,
                target_kind_code => $right->right_type->target_kind_code,
            };
        }
        my $grant_key = $right->is_granted ? 0 : 1;
        if ($right->right_type->target_kind_code ne '') {
            my $targets = $right->targets;
            if (@$targets) {
                for my $target (@$targets) {
                    push @{ $rights_by_grant{$grant_key}->{$right->right_type_id} }, $target->reference_obj->right_target_description;
                }
            }
        }
    }

    my $row = $tab->{content}->{config}->{units}->[0];
    while (my ($content_index, $rights_ref) = each %rights_by_grant) {
        while (my ($right_type_id, $targets) = each %$rights_ref) {
            push @{ $row->[$content_index]->{content} }, sprintf('%s (%s)', $right_types{$right_type_id}->{display_label}, $right_types{$right_type_id}->{target_kind_code});

            my $ref = {
                type => 'DataTable',
                config => {
                    table_config => {
                        columnset => [
                            {
                                key   => 'index',
                                label => '#',
                            },
                            {
                                key   => 'description',
                                label => 'Description',
                            },
                        ],
                        recordset => [],
                    },
                },
            };
            push @{ $row->[$content_index]->{content} }, $ref;

            my $count = 1;
            for my $target (sort @$targets) {
                push @{ $ref->{config}->{table_config}->{recordset} }, {
                    index       => $count,
                    description => $target,
                };
                $count++;
            }
        }
    }

    return $tab;
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
