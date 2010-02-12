package IC::M::FileResource::AttrKind;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_file_resource_attr_kinds',
    columns => [
        code                 => { type => 'varchar', not_null => 1, primary_key => 1, length => 30 },

        __PACKAGE__->boilerplate_columns,

        display_label        => { type => 'varchar', not_null => 1, length => 100 },
        description          => { type => 'text', not_null => 1 },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown File Resource Attribute Kind');
}

1;

__END__
