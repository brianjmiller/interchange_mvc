package IC::M::RightType;

use strict;
use warnings;

use IC::M::RightTypeTargetKind;
use IC::M::Right;

use base qw(IC::Model::Rose::Object);

__PACKAGE__->meta->setup(
    table       => 'ic_right_types',
    columns     => [
        id               => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_right_types_id_seq' },

        __PACKAGE__->boilerplate_columns,

        code             => { type => 'varchar', not_null => 1, length => 50 },
        display_label    => { type => 'varchar', not_null => 1, length => 100 },
        description      => { type => 'text', not_null => 1, default => '' },
        target_kind_code => { type => 'varchar', length => 30 },
    ],
    unique_key  => [
         [ qw( code target_kind_code ) ],
    ],
    foreign_keys    => [
        target_kind => {
            class       => 'IC::M::RightTypeTargetKind',
            key_columns => { target_kind_code => 'code' },
        },
    ],
    relationships => [
        rights  => {
            type        => 'one to many',
            class       => 'IC::M::Right',
            column_map  => {
                id => 'right_type_id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;

    my $return = $self->code . (defined $self->target_kind ? ' - ' . $self->target_kind->display_label : '');
    $return ||= $self->id;

    return $return || 'Unknown Right Type';
}

sub is_valid_type {
    my ($self, $code, $target) = @_;

    my %arg = (code => $code);
    if ($target) {
        $target = $target->[0] if ref $target eq 'ARRAY';
        $arg{target_kind_code} = $target->rights_class->implements_type_target;
    }

    my ($right) = @{ IC::M::RightType::Manager->get_objects( query => [ %arg ] ) };
    return $right if $right;

    return;
}

1;

__END__
