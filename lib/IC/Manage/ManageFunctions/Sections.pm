package IC::Manage::ManageFunctions::Sections;

use strict;
use warnings;

use IC::M::ManageFunction;
use IC::M::ManageFunction::Section;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::ManageFunction::Section' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::ManageFunction::Section::Manager' );
class_has '+_model_display_name'        => ( default => 'Function Section' );
class_has '+_model_display_name_plural' => ( default => 'Function Sections' );
class_has '+_sub_prefix'                => ( default => 'section' );
class_has '+_func_prefix'               => ( default => 'ManageFunctions__Sections_section' );

no Moose;
no MooseX::ClassAttribute;

sub sectionList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
}

sub sectionAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub sectionProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $values = $args->{context}->{f};

    my $statuses = $self->_model_class->statuses;

    my $status_options = [];
    for my $status (keys %$statuses) {
        push @$status_options, { 
            value    => $status,
            selected => ((defined $values->{status} and $values->{status} eq $status) ? ' selected="selected"' : ''),
            display  => $statuses->{$status},
        };
    }

    $args->{context}->{include_options}->{statuses} = $status_options;

    return;
}

sub sectionDrop {
    my $self = shift;
    return $self->_common_drop(@_);
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
