package IC::Manage::Roles;

use strict;
use warnings;

use IC::M::Role;
use IC::Manage::Users;
use IC::Manage::Rights;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::Role' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::Role::Manager' );
class_has '+_model_display_name'        => ( default => 'Role' );
class_has '+_model_display_name_plural' => ( default => 'Roles' );
class_has '+_sub_prefix'                => ( default => 'role' );
class_has '+_func_prefix'               => ( default => 'Roles_role' );
class_has '+_list_cols'                 => (
    default => sub {
        [
            {
                display => 'Display Label',
                method  => 'display_label',
            },
            {
                display => 'Description',
                method  => 'description',
            },
        ],
    },
);

no Moose;
no MooseX::ClassAttribute;

my $_users_manage_class  = 'IC::Manage::Users';
my $_rights_manage_class = 'IC::Manage::Rights';

sub roleList {
    my $self = shift;
    return $self->_common_list(@_);
}

sub _list_0_hook {
    my $self = shift;
    my $content = shift;

    push @$content, $self->_search_by_form( as_title => 1, field => 'display_label' );

    return;
}
    
sub _search_by_form {
    my $self = shift;
    my $args = { @_ };
    
    my $_func_prefix = $self->_func_prefix; 
    
    my @html;

    my $form_action_uri = $self->manage_function_uri(
        method => 'List',
        step   => 1,
    );
    if ($form_action_uri ne '') {
        push @html, "<tr>\n";
        push @html, "<td class=\"list_table_" . (defined $args->{as_title} && $args->{as_title} ? 'title' : 'datum') . "_cell\"> Search on Display Label: </td>\n";
        push @html, "<td class=\"list_table_datum_cell\">\n";
        push @html, "<form action=\"$form_action_uri\">\n";
        push @html, "<input type=\"hidden\" name=\"mode\" value=\"search\" />\n";
        push @html, "<input type=\"hidden\" name=\"search_by[]\" value=\"$args->{field}=ilike\" />\n";
        push @html, "<input type=\"text\" name=\"$args->{field}\" size=\"20\" maxlength=\"50\" />\n";
        push @html, "<input type=\"submit\" value=\"Search\" />";
        push @html, "</form>\n";
        push @html, "<br />\n";
        push @html, "</td>\n";
        push @html, "</tr>\n";
    }
    
    return @html;
}

sub roleAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

sub roleProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

sub roleDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

sub roleDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

sub _detail_generic_hook {
    my $self = shift;
    my $object = shift;
    my $content = shift;

    my ($left, $right, $bottom, $links) = @$content{ qw(left right bottom action_links) };
    
    for ($left) {
        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Has Roles';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
        #push @$_, $self->_object_manage_function_link('SelectRoles', $object, label => 'Select&nbsp;Roles');
        push @$_, '</td>';
        push @$_, '</tr>';
        my $has_roles = $object->has_roles;
        if (@$has_roles) {
            for my $has_role (@{ $object->has_roles }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell" colspan="2">';
                push @$_, $self->_object_manage_function_link(
                    'DetailView',
                    $has_role,
                    label => $has_role->manage_description,
                );
                push @$_, '</td>';
                push @$_, '</tr>';
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No roles assigned yet.</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';

        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Has Users';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
        push @$_, $_users_manage_class->manage_function_link(
            method     => 'Add',
            click_text => '[&nbsp;Add&nbsp;User&nbsp;]',
            query      => {
                role_id => $object->id,
            },
            role       => $self->_controller->role,
            controller => $self->_controller,
        );
        push @$_, '</td>';
        push @$_, '</tr>';
        my $users = $object->users;
        if (@$users) {
            for my $user (@{ $object->users }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $user->manage_description;
                push @$_, '</td>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $_users_manage_class->_object_manage_function_link(
                    'DetailView',
                    $user,
                    label      => 'Details',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, $_users_manage_class->_object_manage_function_link(
                    'Properties',
                    $user,
                    label      => 'Edit',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, $_users_manage_class->_object_manage_function_link(
                    'Drop',
                    $user,
                    label      => 'Drop',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, '</td>';
                push @$_, '</tr>';
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No users assigned yet.</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';

        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Roles Using this Role';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
        push @$_, '</td>';
        push @$_, '</tr>';
        my $roles_using = $object->roles_using;
        if (@$roles_using) {
            for my $using_role (@{ $object->roles_using }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell" colspan="2">';
                push @$_, $self->_object_manage_function_link(
                    'DetailView',
                    $using_role,
                    label => $using_role->manage_description,
                );
                push @$_, '</td>';
                push @$_, '</tr>';
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No roles using this one.</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';
    }

    for ($right) {
        push @$_, '<table class="detail_sub_table" style="width: 90%;">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell" colspan="2">';
        push @$_, 'Rights';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" colspan="2">';
        push @$_, $_rights_manage_class->manage_function_link(
            method     => 'Add',
            click_text => '[&nbsp;Add&nbsp;Right&nbsp;]',
            query      => {
                role_id => $object->id,
            },
            role       => $self->_controller->role,
            controller => $self->_controller,
        );
        push @$_, '</td>';
        push @$_, '</tr>';
        my $rights = $object->rights;
        if (@$rights) {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell">Type</td>';
            push @$_, '<td class="detail_table_datum_cell">Target Kind</td>';
            push @$_, '<td class="detail_table_datum_cell">Is Granted?</td>';
            push @$_, '<td class="detail_table_datum_cell">Options</td>';
            push @$_, '</tr>';
            for my $right (@{ $object->rights }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $right->right_type->display_label;
                push @$_, '</td>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $right->right_type->target_kind_code || '&lt;None&gt;';
                push @$_, '</td>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $right->is_granted ? 'Yes' : 'No';
                push @$_, '</td>';
                push @$_, '<td class="detail_table_datum_cell">';
                push @$_, $_rights_manage_class->_object_manage_function_link(
                    'DetailView',
                    $right,
                    label      => 'Details',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, $_rights_manage_class->_object_manage_function_link(
                    'Properties',
                    $right,
                    label      => 'Edit',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, $_rights_manage_class->_object_manage_function_link(
                    'Drop',
                    $right,
                    label      => 'Drop',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                );
                push @$_, '</td>';
                push @$_, '</tr>';
                if ($right->right_type->target_kind_code ne '') {
                    my $target_model_class        = $right->right_type->target_kind->model_class;

                    my $targets = $right->targets;
                    if (@$targets) {
                        for my $target (@$targets) {
                            push @$_, '<tr>';
                            push @$_, '<td class="detail_table_datum_cell" colspan="4" style="padding-left: 30px;">';
                            push @$_, $target->manage_description( simple => 1 );
                            push @$_, '</td>';
                            push @$_, '</tr>';
                        }
                    }
                    else {
                        push @$_, '<tr>';
                        push @$_, '<td class="detail_table_datum_cell" colspan="4" style="padding-left: 30px;">';
                        push @$_, 'No targets identified yet.';
                        push @$_, '</td>';
                        push @$_, '</tr>';
                    }
                }
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No rights assigned yet.</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';
    }

    return;
}

1;

__END__
