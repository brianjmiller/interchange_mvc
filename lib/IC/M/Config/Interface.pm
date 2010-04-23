#
# TODO: check to see if IC::Graph could be leveraged in place of the view
#
package IC::M::Config::Interface;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

use IC::M::Config::InterfaceInputKind;

__PACKAGE__->meta->setup(
    table => 'ic_config_interface_structure',
    columns => [
        id           => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_config_interface_structure_id_seq' },

        __PACKAGE__->boilerplate_columns,

        parent_id    => { type => 'integer' },
        branch_order => { type => 'integer' },
        lookup_value => { type => 'varchar', length => 70, not_null => 1 },
    ],
    unique_key   => [ 'parent_id', 'lookup_value' ],
    foreign_keys => [
        parent => {
            class       => 'IC::M::Config::Interface',
            key_columns => {
                parent_id => 'id',
            },
        },
    ],
    relationships => [
        leaf => {
            type        => 'one to one',
            class       => 'IC::M::Config::InterfaceLeaf',
            key_columns => {
                id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->lookup_value || $self->id || 'Unknown Config Interface Node');
}

#
# TODO: this probably belongs in a mixin       
#
sub get_all_parents {
    my $self = shift;
    my $args = { @_ };

    $args->{as_object} ||= 0;
    
    my @parents;
    
    my $obj = $self;
    while (my $parent = $obj->parent) {
        if ($args->{as_object}) {
            push @parents, $parent;
        }
        else {
            push @parents, $parent->id;
        }
    
        $obj = $obj->parent;
    }

    return wantarray ? @parents : \@parents;
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
