package IC::Manage::RightTypes;

use strict;
use warnings;

use IC::M::RightType;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

my $_target_kind_class     = __PACKAGE__->_root_model_class() . '::RightTypeTargetKind';
my $_target_kind_class_mgr = $_target_kind_class . '::Manager';

class_has '+_class'                     => ( default => 'RightTypes' );
class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::RightType' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::RightType::Manager' );
class_has '+_model_display_name'        => ( default => 'Right Type' );
class_has '+_model_display_name_plural' => ( default => 'Right Types' );

class_has '+_field_adjustments'           => (
    default => sub {
        {
            target_kind_code  => {
                field_type  => 'SelectField',
                get_choices => sub {
                    my $self = shift;

                    my $options = [];
                    for my $obj (@{ $_target_kind_class_mgr->get_objects( sort_by => 'display_label' ) }) {
                        push @$options, {
                            value => $obj->code . '',
                            label => $obj->display_label,
                        };
                    }

                    return $options;
                },
                value_builder => {
                    code => sub {
                        my $self = shift;
                        my $object = shift;
                        my $params = shift;

                        if ($params->{target_kind_code} eq '') {
                            return undef, [];
                        }
                        else {
                            return $params->{target_kind_code}, [];
                        }
                    },
                },
            },
        },
    },
);


no Moose;
no MooseX::ClassAttribute;

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
