package IC::ManageRole::Drop;

use Moose::Role;

with 'IC::ManageRole::Base';
with 'IC::ManageRole::ObjectAdjuster::Simple';

has '+_object_adjust_simple_label' => (
    default => 'Drop',
);
has '+_object_adjust_simple_subclass' => (
    default => 'Drop',
);

no Moose;

sub _simple_object_adjust_ui_meta_struct {
    #warn "IC::ManageRole::Drop::_simple_object_adjust_ui_meta_struct";
    my $self = shift;
    my $struct = shift;
    my $object = shift;

    $struct->{+__PACKAGE__} = 1;

    $struct->{config}->{caption} = 'Are you sure you wish to delete the following ' . $self->_model_display_name . ': <span class="emphasized">' . $object->manage_description . '</span>';

    return;
};

sub _save_object_adjust {
    #warn "IC::ManageRole::Drop::_save_object_adjust";
    my $self = shift;
    my $object = shift;

    $object->delete;

    return;
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
