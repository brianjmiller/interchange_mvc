package IC::M::Config::Setting::Option;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_config_setting_options',
    columns => [
        id            => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_config_setting_options_id_seq' },

        __PACKAGE__->boilerplate_columns,

        setting_code  => { type => 'varchar', length => 255, not_null => 1 },
        level_code    => { type => 'varchar', length => 30, not_null => 1 },
        code          => { type => 'varchar', length => 255, not_null => 1 },
        display_label => { type => 'varchar', length => 255, not_null => 1 },

        is_default   => { type => 'boolean', not_null => 1, },
        sort_order   => { type => 'integer' },
    ],
    unique_keys  => [
        [ qw( setting_code level_code code ) ],
        [ 'display_label' ],
    ],
    foreign_keys => [
        level => {
            class       => 'IC::M::Config::Level',
            key_columns => {
                level_code => 'code',
            },
        },
        setting => {
            class       => 'IC::M::Config::Setting',
            key_columns => {
                setting_code => 'code',
            },
        },
    ],
    relationships => [
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Config Setting Option');
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
