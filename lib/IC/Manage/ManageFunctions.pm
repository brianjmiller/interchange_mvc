package IC::Manage::ManageFunctions;

use strict;
use warnings;

use IC::M::ManageFunction;
use IC::M::ManageFunction::Section;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::ManageFunction' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::ManageFunction::Manager' );
class_has '+_model_display_name'        => ( default => 'Function' );
class_has '+_model_display_name_plural' => ( default => 'Functions' );
class_has '+_sub_prefix'                => ( default => 'function' );
class_has '+_func_prefix'               => ( default => 'ManageFunctions_function' );

class_has '+_list_paging_provider'      => ( default => 'server' );

no Moose;
no MooseX::ClassAttribute;

my $_section_class     = __PACKAGE__->_model_class() . '::Section';
my $_section_class_mgr = $_section_class . '::Manager';

sub functionList {
    my $self = shift;
    return $self->_common_list(@_);
}

sub _list_0_hook {
    my $self = shift;
    my $content = shift;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;

    my $sections = $_section_class_mgr->get_objects;
    if (@$sections) {
        push @$content, "<tr>";
        push @$content, "<td class=\"list_table_title_cell\">List by Section</td>";
        push @$content, "<td class=\"list_table_title_cell_centered\">Function Count</td>";
        push @$content, "</tr>\n";

        for my $section (@$sections) {
            my $section_code = $section->code;

            push @$content, "<tr>";
            push @$content, "<td class=\"list_table_datum_cell\">";
            push @$content, $self->manage_function_link(
                step       => $self->_step + 1,
                click_text => $section->display_label,
                query      => {
                    mode         => 'list',
                    'list_by[]'  => 'section_code',
                    section_code => $section_code,
                },
            );
            push @$content, "</td>";
            push @$content, "<td class=\"list_table_datum_cell_centered\">";
            push @$content, $_model_class_mgr->get_objects_count( query => [ section_code => $section_code ] );
            push @$content, "</td>";
            push @$content, "</tr>\n";
        }
    }

    return;
}

sub functionAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub functionProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $values = $args->{context}->{f};

    my $section_options = [];
    my $sections = $_section_class_mgr->get_objects(
        query => [
            status => MGMT_FUNC_SECTION_STATUS_ACTIVE,
        ],
    );
    for my $section (sort { $a->display_label cmp $b->display_label } @$sections) {
        push @$section_options, { 
            value    => $section->code,
            selected => ((defined $values->{section_code} and $values->{section_code} eq $section->code) ? ' selected="selected"' : ''),
            display  => $section->display_label,
        };
    }

    $args->{context}->{include_options}->{sections} = $section_options;

    return;
}

sub functionDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub functionDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
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
