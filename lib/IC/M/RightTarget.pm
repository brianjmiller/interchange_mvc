package IC::M::RightTarget;

use strict;
use warnings;

use base qw(IC::Model::Rose::Object);

__PACKAGE__->meta->setup(
    table       => 'ic_right_targets',
    columns     => [
        id         => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_right_targets_id_seq' },

        __PACKAGE__->boilerplate_columns,

        right_id   => { type => 'integer', not_null => 1 },
        ref_obj_pk => { type => 'text', not_null => 1 },
    ],
    foreign_keys    => [
        right_type  => {
            class       => 'IC::M::Right',
            key_columns => { right_id => 'id' },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;

    my $return = $self->right_id . ' - ' . $self->ref_obj_pk;
    $return ||= $self->id;

    return $return || 'Unknown Right Target';
}

sub implements_type_target {
    return undef;
}

#
# TODO: implement method for retrieval of a reference object
#

1;

__END__
