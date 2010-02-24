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
