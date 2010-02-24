package IC::M::File::Property;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_file_properties',
    columns => [
        id                    => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_file_properties_id_seq' },

        __PACKAGE__->boilerplate_columns,

        file_id               => { type => 'integer', not_null => 1, },
        file_resource_attr_id => { type => 'integer', not_null => 1, },
        value                 => { type => 'text', not_null => 1, },
    ],
    foreign_keys => [
        file => {
            class       => 'IC::M::File',
            key_columns => {
                file_id => 'id',
            },
        },
        file_resource_attr => {
            class       => 'IC::M::FileResource::Attr',
            key_columns => {
                file_resource_attr_id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->id || 'Unknown File Property');
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
