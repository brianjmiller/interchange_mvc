package IC::M::Version;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table           => 'ic_versions',
    columns         => [
        id            => { type => 'integer', not_null => 1, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,
    ],
);

__PACKAGE__->make_manager_package;

1;

__END__
