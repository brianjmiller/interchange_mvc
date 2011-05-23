#
# classes using this mixin should implement two methods:
#
#     _mixin_model_descriptor:
#
#       returns a name that can be used to identify the model being acted on
#
#     _get_change_status_struct:
#
#       returns a structure that is a hash of hash refs where the keys of the 
#       outer hash represent statuses that an object is changing from, with 
#       the keys of the inner hash being statuses that an object is changing 
#       to whose value is callback subroutine to run when the transition occurs
#
#############################################################################
package IC::M::_AdvancedStatus_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

use IC::M::_Dispatch_Triggers;

__PACKAGE__->export_tag(
    all => [
        qw(
            can_change_status
            change_status
        ),
    ],
);

sub can_change_status {
    my $self = shift;
    my $new_status = shift;
    my %args = @_;

    return IC::M::_Dispatch_Triggers::_can_change_value(
        $self,
        $new_status,
        _get_trigger_structure_method => '_get_change_status_struct',
        %args,
    );
}

sub change_status {
    my $self = shift;
    my $new_status = shift;
    my %args = @_;

    return IC::M::_Dispatch_Triggers::_change_value_with_trigger(
        $self,
        $new_status,
        _field                        => (defined $args{_field} ? delete $args{_field} : 'status_code'),
        _get_trigger_structure_method => '_get_change_status_struct',
        _action_code                  => 'status_change',
        %args,
    );
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
