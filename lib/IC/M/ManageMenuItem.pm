package IC::M::ManageMenuItem;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

use IC::M::ManageClass::Action;
use IC::M::ManageMenuItemLeaf;

use IC::M::_Tree_MixIn qw( :all );

__PACKAGE__->meta->setup(
    table => 'ic_manage_menu_items',
    columns => [
        id                             => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_manage_menu_items_id_seq' },

        __PACKAGE__->boilerplate_columns,

        parent_id                      => { type => 'integer' },
        branch_order                   => { type => 'integer' },
        lookup_value                   => { type => 'varchar', length => 70, not_null => 1 },
        manage_class_action_id         => { type => 'integer' },
        manage_class_action_addtl_args => { type => 'varchar', length => 255 },
    ],
    unique_key => [ 'parent_id', 'lookup_value' ],
    foreign_keys => [
        manage_class_action => {
            class       => 'IC::M::ManageClass::Action',
            key_columns => {
                manage_class_action_id => 'id',
            },
        },
        parent => {
            class       => 'IC::M::ManageMenuItem',
            key_columns => {
                parent_id => 'id',
            },
        },
    ],
    relationships => [
        children => {
            type => 'one to many',
            class => 'IC::M::ManageMenuItem',
            key_columns => {
                id => 'parent_id',
            },
        },
        leaf => {
            type        => 'one to one',
            class       => 'IC::M::ManageMenuItemLeaf',
            key_columns => {
                id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->lookup_value || $self->id || 'Unknown Manage Menu Item');
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
