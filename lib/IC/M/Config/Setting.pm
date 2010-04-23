package IC::M::Config::Setting;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table         => 'ic_config_settings',
    columns       => [
        code                      => { type => 'varchar', not_null => 1, length => 50, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,

        display_label             => { type => 'varchar', not_null => 1, length => 100 },
        should_cascade            => { type => 'boolean', not_null => 1 },
        should_combine            => { type => 'boolean', not_null => 1 },
        is_web_editable           => { type => 'boolean', not_null => 1 },
        interface_input_kind_code => { type => 'varchar', not_null => 1, length => 30 },
        interface_node_id         => { type => 'integer', not_null => 1 },
    ],
    unique_keys   => [ 'display_label' ],
    relationships => [
        level_map => {
            class       => 'IC::M::Config::SettingLevelMap',
            type        => 'one to many',
            key_columns => {
                code => 'setting_code',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Config Setting');
}

1;

__END__

=pod

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see: http://www.gnu.org/licenses/ 

=cut
