package IC::M::Config::Value;

use strict;
use warnings;

use IC::M::Config;
use IC::M::Config::Setting::Option;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table         => 'ic_config_values',
    columns       => [
        id        => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_config_values_id_seq' },

        __PACKAGE__->boilerplate_columns,

        config_id => { type => 'integer', not_null => 1 },
        option_id => { type => 'integer', not_null => 1 },
    ],
    foreign_keys  => [
        config => {
            class       => 'IC::M::Config',
            key_columns => {
                config_id => 'id',
            },
        },
        option => {
            class       => 'IC::M::Config::Setting::Option',
            key_columns => {
                option_id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->config_id . ' - ' . $self->option_id || $self->id || 'Unknown Config Value');
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
