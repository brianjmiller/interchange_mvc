#
# classes using this mixin should implement two methods:
#
#     _mixin_model_descriptor:
#
#       returns a name that can be used to identify the model being acted on
#
#     _get_change_kind_struct:
#
#       returns a structure that is a hash of hash refs where the keys of the 
#       outer hash represent statuses that an object is changing from, with 
#       the keys of the inner hash being statuses that an object is changing 
#       to whose value is callback subroutine to run when the transition occurs
#
#############################################################################
package IC::M::_AdvancedKind_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

use IC::M::_Dispatch_Trigger_MixIn qw( _change_value_with_trigger );

__PACKAGE__->export_tag(
    all => [
        qw(
            change_kind
            _change_value_with_trigger
        ),
    ],
);

sub change_kind {
    my $self = shift;
    my $new_kind_code = shift;
    my %args = @_;

    return $self->_change_value_with_trigger(
        $new_kind_code,
        _field                        => (defined $args{_field} ? delete $args{_field} : 'kind_code'),
        _get_trigger_structure_method => '_get_change_kind_struct',
        _action_code                  => 'kind_change',
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
