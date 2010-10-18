package IC::M::ManageClass;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

use IC::M::_Manage_MixIn qw( :all );

__PACKAGE__->meta->setup(
    table => 'ic_manage_classes',
    columns => [
        code                  => { type => 'varchar', length => 100, not_null => 1, primary_key => 1 },

        __PACKAGE__->boilerplate_columns,
    ],
    relationships => [
        actions => {
            type => 'one to many',
            class => 'IC::M::ManageClass::Action',
            key_columns => {
                code => 'class_code',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->code || 'Unknown Manage Class');
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
