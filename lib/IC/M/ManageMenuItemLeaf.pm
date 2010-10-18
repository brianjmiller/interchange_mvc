package IC::M::ManageMenuItemLeaf;
        
use strict;
use warnings;
            
use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_manage_menu_items_tree_view',
    columns => [
        id            => { type => 'integer', not_null => 1, primary_key => 1 },
        parent_id     => { type => 'integer' },
        level         => { type => 'integer', not_null => 1 },
        branch        => { type => 'text', not_null => 1 },
        pos           => { type => 'integer', not_null => 1 },
    ],      
    foreign_keys => [
        parent => {
            class => 'IC::M::ManageMenuItemLeaf',
            key_columns => {
                parent_id => 'id',
            },
        },
    ],
    relationships => [
        properties => {
            type        => 'one to one',
            class       => 'IC::M::ManageMenuItem',
            key_columns => {
                id => 'id',
            },
        },
    ],
    #
    # TODO: this is provided for in new RDBO's I believe
    #
    #view => '1',
);          

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift; 
    return ($self->id || 'Unknown Manage Menu Item Leaf');
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
