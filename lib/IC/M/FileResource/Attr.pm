package IC::M::FileResource::Attr;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_file_resource_attrs',
    columns => [
        id                   => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_file_resource_attrs_id_seq' },

        __PACKAGE__->boilerplate_columns,

        file_resource_id     => { type => 'integer', not_null => 1, },
        code                 => { type => 'varchar', not_null => 1, length => 100 },
        kind_code            => { type => 'varchar', not_null => 1, length => 30 },
        display_label        => { type => 'varchar', not_null => 1, length => 100 },
        description          => { type => 'text', not_null => 1 },
    ],
    unique_key => [ 'file_resource_id', 'code' ],
    foreign_keys => [
        file_resource => {
            class       => 'IC::M::FileResource',
            key_columns => {
                file_resource_id => 'id',
            },
        },
        kind          => {
            class       => 'IC::M::FileResource::AttrKind',
            key_columns => {
                kind_code => 'code',
            },
        },
    ],
    relationships => [
        properties => {
            type => 'one to many',
            class => 'IC::M::File::Property',
            key_columns => {
                id => 'file_resource_attr_id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || $self->id || 'Unknown File Resource Attribute');
}

1;

__END__
