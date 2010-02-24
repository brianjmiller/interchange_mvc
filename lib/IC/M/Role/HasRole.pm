package IC::M::Role::HasRole;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table           => 'ic_roles_has_roles',
    columns         => [
        role_id     => { type => 'integer', not_null => 1 },
        has_role_id => { type => 'integer', not_null => 1 },

        __PACKAGE__->boilerplate_columns,
    ],
    primary_key_columns => [ qw( role_id has_role_id ) ],
    foreign_keys    => [
        role        => {
            class       => 'IC::M::Role',
            key_columns => { role_id => 'id' },
        },
        has_role    => {
            class       => 'IC::M::Role',
            key_columns => { has_role_id => 'id' },
        },
    ],
);

__PACKAGE__->make_manager_package;

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
