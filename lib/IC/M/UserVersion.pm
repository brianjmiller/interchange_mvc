package IC::M::UserVersion;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_user_versions',
    columns => [
        id            => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_user_versions_id_seq' },

        __PACKAGE__->boilerplate_columns,

        display_label => { type => 'varchar', not_null => 1, length => 50 },
    ],
    unique_key => [ 'display_label' ], 
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->id || 'Unknown User Version');
}

1;

__END__
