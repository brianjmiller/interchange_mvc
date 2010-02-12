package IC::M::ManageFunction::Section;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

# TODO: move these to a lookup
my $status_constant_prefix = 'MGMT_FUNC_SECTION_STATUS_';
use constant MGMT_FUNC_SECTION_STATUS_INACTIVE => 0;
use constant MGMT_FUNC_SECTION_STATUS_ACTIVE   => 1;
our $statuses = {
    MGMT_FUNC_SECTION_STATUS_INACTIVE, 'Inactive',
    MGMT_FUNC_SECTION_STATUS_ACTIVE,   'Active',
};

{
    no strict 'refs';

    my $class = __PACKAGE__ . '::';
    my @_export_constant_names = (grep { /^$status_constant_prefix/ } keys %$class);
    sub import {
        my $namespace = caller(0) . '::';
        {
            for my $key (@_export_constant_names) {
                my $name  = "$namespace$key";
                *{"$name"} = *{$class.$key};
            }
        }
    }
}

#
#
#
sub statuses {
    return wantarray ? %$statuses : $statuses;
}

__PACKAGE__->meta->setup(
    table => 'ic_manage_function_sections',
    columns => [
        code          => { type => 'varchar', not_null => 1, primary_key => 1, length => 30 },

        __PACKAGE__->boilerplate_columns,

        status        => { type => 'integer', not_null => 1 },
        display_label => { type => 'varchar', not_null => 1, default => '', length => 20 },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Manage Function Section');
}

1;

__END__
