package IC::M::TimeZone;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_time_zones',
    columns => [
        code       => { type => 'varchar', length => 50, not_null => 1, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,

        utc_offset => { type => 'numeric', not_null => 1 },
        is_visible => { type => 'boolean', not_null => 1 },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->code || 'Unknown Time Zone');
}

1;

__END__
