package IC::M::ManageClass::Action;

use strict;
use warnings;

use IC::M::RightTarget::SiteMgmtAction;

use base qw( IC::Model::Rose::Object );

use IC::M::_Manage_MixIn qw( :all );

__PACKAGE__->meta->setup(
    table => 'ic_manage_class_actions',
    columns => [
        id            => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_manage_class_actions_id_seq' },

        __PACKAGE__->boilerplate_columns,

        class_code    => { type => 'varchar', not_null => 1, length => 100 },
        code          => { type => 'varchar', not_null => 1, length => 100 },
        display_label => { type => 'varchar', not_null => 1, length => 100 },
        is_primary    => { type => 'boolean', not_null => 1 },
    ],
    unique_keys => [ 
        [ 'class_code', 'code' ],
        [ 'display_label' ],
    ],
    foreign_keys => [
        class => {
            class       => 'IC::M::ManageClass',
            key_columns => {
                class_code => 'code',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

#
#
#
sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->class_code . ' - ' . $self->code || 'Unknown Manage Class Action');
}

sub rights_class { 'IC::M::RightTarget::SiteMgmtAction' }

sub right_target_description {
    my $self = shift;

    return sprintf '%s: %s', $self->class_code, $self->display_label;
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
