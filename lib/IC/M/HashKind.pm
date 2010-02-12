package IC::M::HashKind;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_hash_kinds',
    columns => [
        code          => { type => 'varchar', length => 30, not_null => 1, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,

        display_label => { type => 'varchar', length => 100, not_null => 1 },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Hash Kind');
}

1;

__END__
