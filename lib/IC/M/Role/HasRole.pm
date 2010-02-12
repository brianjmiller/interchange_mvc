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
