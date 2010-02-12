package IC::M::ManageFunction;

use strict;
use warnings;

use IC::M::RightTarget::SiteMgmtFunc;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_manage_functions',
    columns => [
        code                  => { type => 'varchar', length => 70, not_null => 1, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,

        section_code          => { type => 'varchar', length => 30, not_null => 1 },
        developer_only        => { type => 'boolean', not_null => 1, default => 'false' },
        in_menu               => { type => 'boolean', not_null => 1, default => 'false' },
        sort_order            => { type => 'smallint', not_null => 1, default => 0 },
        display_label         => { type => 'varchar', length => 100, not_null => 1 },
        extra_params          => { type => 'text', not_null => 1, default => '' },
        help_copy             => { type => 'text', not_null => 1, default => '' },
    ],
    foreign_keys => [
        section => {
            class => 'IC::M::ManageFunction::Section',
            key_columns => {
                section_code => 'code',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Manage Function');
}

sub rights_class { 'IC::M::RightTarget::SiteMgmtFunc' }

1;

__END__
