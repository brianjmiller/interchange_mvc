package IC::M::RightTypeTargetKind;

use strict;
use warnings;

use IC::M::RightType;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_right_type_target_kinds',
    columns => [
        code          => { type => 'varchar', not_null => 1, length => 30, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,

        display_label => { type => 'varchar', not_null => 1, length => 100 },
        model_class   => { type => 'varchar', not_null => 1, length => 100 },
        relation_name => { type => 'varchar', not_null => 1, length => 100 },
    ],
    unique_keys => [
        [ 'display_label' ],
        [ 'model_class' ],
        [ 'relation_name' ],
    ],
    relationships   => [
        right_types => {
            class       => 'IC::M::RightType',
            type        => 'one to many',
            key_columns => {
                code => 'target_kind_code',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Right Type Target Kind');
}

1;

__END__
