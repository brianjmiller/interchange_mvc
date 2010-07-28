package IC::Manage;

use strict;
use warnings;

use Encode qw( encode_utf8 );
use File::MimeInfo::Magic ();
use File::Path ();
use File::Spec ();
use IO::Scalar;
use JSON::Syck ();

use IC::Config;
use IC::M::File;
use IC::M::FileResource;

#
# TODO: these should be overridable
#
use IC::C::Manage::Component::FunctionResult::Generic;
use IC::C::Manage::Component::FunctionResult::Form;
use IC::C::Manage::Component::FunctionResult::DetailView;
use IC::C::Manage::Component::FunctionResult::ListPaginated;

use Moose;
use MooseX::ClassAttribute;

class_has '_root_model_class'          => ( is => 'ro', default => 'IC::M' );
class_has '_icon_path'                 => ( is => 'ro', default => '/ic/images/icons/file.png' );
class_has '_model_class'               => ( is => 'ro', default => undef );
class_has '_model_class_mgr'           => ( is => 'ro', default => undef );
class_has '_model_display_name'        => ( is => 'ro', default => undef );
class_has '_model_display_name_plural' => ( is => 'ro', default => undef );
class_has '_sub_prefix'                => ( is => 'ro', default => undef );
class_has '_func_prefix'               => ( is => 'ro', default => undef );
class_has '_parent_manage_class'       => ( is => 'ro', default => undef );
class_has '_parent_model_link_field'   => ( is => 'ro', default => undef );
class_has '_role_class'                => ( is => 'ro', default => 'IC::M::Role' );
class_has '_file_class'                => ( is => 'ro', default => 'IC::M::File' );
class_has '_file_resource_class'       => ( is => 'ro', default => 'IC::M::FileResource' );
class_has '_file_resource_class_mgr'   => ( is => 'ro', default => 'IC::M::FileResource::Manager' );

class_has '_list_paging_provider'      => ( is => 'ro', default => 'server' );
class_has '_list_page_count'           => ( is => 'ro', default => 25 );
class_has '_list_cols'                 => (
    is      => 'ro', 
    default => sub {
        [
            { 
                display         => 'Description',
                method          => 'manage_description',
                parser          => 'string',
                sortable        => 0,
            },
            {
                display   => 'Date Created',
                method    => 'date_created',
                sortable  => 1,
                parser    => 'stringToDate',
                formatter => 'date',
            },
            {
                display                => 'Last Modified',
                method                 => 'last_modified',
                sortable               => 1,
                parser                 => 'stringToDate',
                formatter              => 'date',
                is_default_sort        => 1,
                default_sort_direction => 'desc',
            },
        ],
    },
);
class_has '_list_additional_functions'       => ( is => 'ro', default => sub { [] } );
class_has '_list_no_filter'                  => ( is => 'ro', default => undef );
class_has '_list_status_field'               => ( is => 'ro', default => undef );
class_has '_list_status_class'               => ( is => 'ro', default => undef );
class_has '_list_status_obj_key_method'      => ( is => 'ro', default => undef );
class_has '_list_status_obj_name_method'     => ( is => 'ro', default => undef );
class_has '_list_kind_field'                 => ( is => 'ro', default => undef );
class_has '_list_kind_class'                 => ( is => 'ro', default => undef );
class_has '_list_kind_obj_key_method'        => ( is => 'ro', default => undef );
class_has '_list_kind_obj_name_method'       => ( is => 'ro', default => undef );

class_has '_properties_referrer_no_override' => ( is => 'ro', default => undef );
class_has '_properties_form_adjustments'     => ( is => 'ro', default => undef );

class_has '_detail_use_default_summary_tab'  => ( is => 'ro', default => 1 );
class_has '_detail_other_mappings'           => ( is => 'ro', default => sub { {} } );
class_has '_detail_suppress_foreign_objects' => ( is => 'ro', default => undef );
class_has '_detail_action_log_configuration' => ( is => 'ro', default => sub { {} } );

class_has '_upload_target_directory'         => ( is => 'ro', default => undef );
class_has '_upload_requires_object'          => ( is => 'ro', default => undef );

has '_class'      => ( is => 'rw', required => 1 );
has '_method'     => ( is => 'rw', required => 1 );
has '_controller' => ( is => 'rw', required => 1 );
has '_step'       => ( is => 'rw', default => 0 );

# indicates whether a response has been set
has '_response'   => ( is => 'rw', default => 0 );

no Moose;
no MooseX::ClassAttribute;

#############################################################################
#
#
#
sub _function { return $_[0]->_class . '_' . $_[0]->_method }

sub execute {
    my $self = shift;
    my %args = @_;

    my $method = $self->_method;
    unless ($self->can( $method )) {
        IC::Exception::ManageFunctionMethodUnknown->throw( error => $method );
    }

    # run the method of the function object, which will call set_response()
    # to configure the response in the controller
    $self->$method(%args);

    unless ($self->_response) {
        IC::Exception->throw('Manage function did not call set_response()');
    }

    return;
}

sub set_response {
    my $self = shift;
    my $args = { @_ };

    unless (defined $args->{type} and $args->{type} ne '') {
        IC::Exception->throw('Argument missing: type');
    }

    if ($args->{type} eq 'component') {
        unless (defined $args->{kind} and $args->{kind} ne '') {
            IC::Exception->throw("Argument missing: component type requires 'kind'");
        }

        #
        # TODO: make this overrideable, and registered
        #
        my $component_class = {
            generic          => 'IC::C::Manage::Component::FunctionResult::Generic',
            form             => 'IC::C::Manage::Component::FunctionResult::Form',
            detail_view      => 'IC::C::Manage::Component::FunctionResult::DetailView',
            list_paginated   => 'IC::C::Manage::Component::FunctionResult::ListPaginated',
        };
        if (exists $component_class->{$args->{kind}}) {
            my $component = $component_class->{$args->{kind}}->new( 
                controller => $self->_controller,
                context    => $args->{context},
            );

            $self->_controller->add_stylesheet(
                kind => 'ic',
                path => 'manage/function.css',
            );
            $self->_controller->render(
                context => {
                    _function => $self->_function,
                    component => $component,
                },
            );
        }
        else {
            IC::Exception->throw("Unrecognized component kind: $args->{kind}");
        }
    }
    elsif ($args->{type} eq 'redirect') {
        unless (defined $args->{url} and $args->{url} ne '') {
            IC::Exception->throw("Argument missing: redirect type requires 'url'");
        }

        $self->_controller->redirect(
            href         => $args->{url},
            add_dot_html => 0,
        );
    }
    else {
        IC::Exception->throw("Unrecognized type: $args->{type}");
    }

    $self->_response(1);

    return;
}

sub set_title {
    my $self = shift;
    my ($action, @objects) = @_;

    my $desc = '';
    for my $object (@objects) {
        $desc .= ' : ' . $object->manage_description;
    }

    $self->_controller->content_title("$action$desc");

    return;
}

sub set_subtitle {
    my $self = shift;
    $self->_controller->content_subtitle( shift );
}

sub manage_function_uri {
    my $invocant = shift;
    my $args = { @_ };

    if (defined $args->{function}) {
        # do nothing they passed exactly what we want
    }
    elsif (defined $args->{class} and defined $args->{method}) {
        $args->{function} = "$args->{class}\_$args->{method}";
    }
    elsif (defined $args->{method}) {
        $args->{function} = $invocant->_func_prefix.$args->{method};
    }
    elsif (ref $invocant) {
        # in this case pull the class, method, and potentially the step
        # from the object instance
        $args->{function} = $invocant->_class . '_' . $invocant->_method;
    }
    else {
        IC::Exception->throw( "Can't determine function for manage_function_uri" );
    }

    my $controller;
    if (ref $invocant) {
        $controller = $invocant->_controller;
    }
    else {
        $controller = $args->{controller};
    }
    unless (defined $controller) {
        my ($package, $filename, $line) = caller(1);
        warn "$package called manage_function_uri as class method without 'controller' argument at line $line ($args->{function})\n";
        return '';
    }

    # perform privilege check unless they pass the arg and it is turned off
    # aka default to on, a failing priv check results in no link rather than
    # throwing an exception
    unless (defined $args->{priv_check} and ! $args->{priv_check}) {
        my $check_func_name = $args->{function};
        my $check_role;
        if (defined $args->{role} and UNIVERSAL::isa($args->{role}, $invocant->_role_class)) {
            $check_role = $args->{role};
        }
        elsif (defined $controller->role) {
            $check_role = $controller->role;
        }
        else {
            my ($package, $filename, $line) = caller(1);
            warn "$package called manage_function_uri but was unable to determine 'role' properties at line $line\n";
            return '';
        }

        my $function_obj = IC::M::ManageFunction->new( code => $args->{function} );
        unless ($function_obj->load( speculative => 1 )) {
            my ($package, $filename, $line) = caller(1);
            warn "Can't locate object for function: $args->{function} called at $package line $line\n";
            return '';
        }

        return '' unless $check_role->check_right(
            'execute', $function_obj,
        );
    }

    $args->{step}  ||= 0;
    $args->{query} ||= {};

    my $url = $controller->url(
        controller => 'manage',
        action     => 'function',
        parameters => {
            _function => $args->{function},
            _step     => $args->{step},
        },
        get        => $args->{query},
        secure     => 1,
    );

    return $url;
}

sub manage_function_link {
    my $invocant = shift;
    my $args = { @_ };

    $args->{link_class} = 'manage_function_link' if not defined $args->{class};
    $args->{link_id}    = '' if not defined $args->{link_id};

    unless (defined $args->{click_text} and $args->{click_text} ne '') {
        IC::Exception::ArgumentMissing->throw( error => 'click_text' );
    }
    my $click_text = delete $args->{click_text};
    my $url = $invocant->manage_function_uri( %$args );

    if ($url ne '') {
        return "<a id=\"$args->{link_id}\" class=\"$args->{link_class}\" href=\"$url\">$click_text</a>";
    }

    return '';
}

sub is_authorized {
    my $invocant = shift;
    my $function = shift;
    my $args = { @_ };

    my $role;
    if (defined $args->{role} and $args->{role} ne '') {
        $role = $args->{role};
    }
    elsif (ref $invocant) {
        $role = $invocant->_controller->role;
    }
    else {
        IC::Exception->throw('is_authorized called as class method without role argument');
    }
    unless (ref $function) {
        $function = IC::M::ManageFunction->new( code => $function )->load;
    }

    return $role->check_right( 'execute', $function );
}

#############################################################################
#
#
#
sub _common_implied_object {
    my $self = shift;

    my $_model_class = $self->_model_class;
    my $_object_name = $self->_model_display_name;
    my $params       = $self->_controller->parameters;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    for my $_pk_field (@_pk_fields) {
        unless (defined $params->{$_pk_field}) {
            IC::Exception::MissingValue->throw( "PK argument ($_pk_field): Unable to retrieve object" );
        }
    }

    my %object_params = map { $_ => $params->{"_pk_$_"} } @pk_fields;

    my $object = $_model_class->new( %object_params );
    unless (defined $object) {
        IC::Exception::ModelInstantiateFailure->throw( $_object_name );
    }
    unless ($object->load(speculative => 1)) {
        IC::Exception::ModelLoadFailure->throw( "Unrecognized $_object_name: " . (join ' => ', %object_params) );
    }

    return $object;
}

sub _object_manage_function_link {
    my $self   = shift;
    my $action = shift;
    my $object = shift;
    my $args   = { @_ };

    # set some defaults
    $args->{label}      ||= '';
    $args->{url_only}   ||= 0;
    $args->{addtl_cgi}  ||= {};
    $args->{addtl_keys} ||= {};

    my $invocant;
    if (ref $object) {
        $invocant  = $object;
    }
    else {
        $invocant = $self->_model_class;
    }

    my %method_params = (
        function => $self->_func_prefix . $action,
        query    => {
            (
                map { 
                    my $val;
                    if ($invocant->can($_)) {
                        $val = $invocant->$_;
                    }
                    elsif (exists $args->{addtl_keys}->{$_}) {
                        $val = $args->{addtl_keys}->{$_};
                    }
                    else {
                        IC::Exception->throw( "No value found for pk field: $_" );
                    }
    
                    "_pk_$_" => $val
                } @{ $invocant->meta->primary_key_columns }
            ),
            %{$args->{addtl_cgi}},
        },
    );
    if (defined $args->{step}) {
        $method_params{step} = $args->{step};
    }
    if (defined $args->{priv_check}) {
        $method_params{priv_check} = $args->{priv_check};
    }
    if (defined $args->{role}) {
        $method_params{role} = $args->{role};
    }

    unless (ref $self) {
        unless (defined $args->{controller}) {
            my ($package, $filename, $line) = caller(1);
            warn "$package called _object_manage_function_link as class method without 'controller' argument at line $line ($method_params{function})\n";
            return '';
        }
        $method_params{controller} = $args->{controller};
    }

    if ($args->{url_only}) {
        return $self->manage_function_uri(%method_params);
    }
    else {
        my $link_format = $args->{link_format} || '[&nbsp;%s&nbsp;]';

        return $self->manage_function_link(
            %method_params,
            click_text => (sprintf $link_format, ($args->{label} || $action)),
        );
    }
}

sub _referer_redirect_response {
    my $self = shift;

    my $params = $self->_controller->parameters;

    $self->set_response(
        type => 'redirect',
        url  => (defined $params->{redirect_referer} ? $params->{redirect_referer} : $self->_controller->url( controller => 'manage', action => 'menu' ) ),
    );

    return;
}

sub _properties_form_hook {
    my $self = shift;
    my $args = { @_ };

    my $params = $self->_controller->parameters;

    for my $field (@{ $self->_model_class->meta->columns }) {
        #warn "$field: $params->{$field}\n";
        my $value = defined $params->{$field} ? $params->{$field} : $args->{context}->{f}->{$field};
        next unless defined $value;

        if ($field->type eq 'datetime' or $field->type eq 'timestamp') {
            my ($date, $time);
            if ($value =~ /T/) {
                ($date, $time) = split /T/, $value;
            }
            else {
                ($date, $time) = split / /, $value;
            }

            @{ $args->{context}->{f} }{ $field.'_yyyy', $field.'_mm', $field.'_dd' } = split /-/, $date;
            @{ $args->{context}->{f} }{ $field.'_HH', $field.'_MM', $field.'_SS' }   = split /:/, $time;
        }
        elsif ($field->type eq 'date') {
            if ($value =~ /T/) {
                ($value) = split /T/, $value;
            }
            @{ $args->{context}->{f} }{ $field.'_yyyy', $field.'_mm', $field.'_dd' } = split /-/, $value;
        }
        elsif ($field->type eq 'time') {
            @{ $args->{context}->{f} }{ $field.'_HH', $field.'_MM', $field.'_SS' } = split /:/, $value;
        }
    }

    return;
}

sub _properties_action_hook {
    my $self = shift;

    my $params = $self->_controller->parameters;

    for my $field (@{ $self->_model_class->meta->columns }) {
        if (grep { $field->type eq $_ } qw( date time datetime timestamp )) {
            my ($date, $time) = ('', '');

            if (
                (defined $params->{$field.'_yyyy'} and $params->{$field.'_yyyy'} ne '')
                and
                (defined $params->{$field.'_mm'} and $params->{$field.'_mm'} ne '')
                and
                (defined $params->{$field.'_dd'} and $params->{$field.'_dd'} ne '')
            ) {
                $date = join '-', delete @$params{ $field.'_yyyy', $field.'_mm', $field.'_dd' };
            }

            if (
                (defined $params->{$field.'_HH'} and $params->{$field.'_HH'} ne '')
                and
                (defined $params->{$field.'_MM'} and $params->{$field.'_MM'} ne '')
                and
                (defined $params->{$field.'_SS'} and $params->{$field.'_SS'} ne '')
            ) {
                $time = join ':', delete @$params{ $field.'_HH', $field.'_MM', $field.'_SS' };
            }

            if ($field->type eq 'datetime' or $field->type eq 'timestamp') {
                if ($date ne '' and $time ne '') {
                    $params->{$field} = join ' ', $date, $time;
                }
                elsif ($date ne '') {
                    $params->{$field} = $date . ' ' . '00:00:00';
                }
                else {
                    $params->{$field} = '';
                }
            }
            elsif ($field->type eq 'date') {
                $params->{$field} = $date;
            }
            elsif ($field->type eq 'time') {
                $params->{$field} = $time;
            }
        }
    }

    return;
}

#
# each element of the search by value contains a single
# query element specification as,
#
#   field = operator
#
# where field matches a field in the model class being
# queried, and the operator matches a query operator
# the model class field understands
#
sub _process_search_by {
    my $self = shift;
    my $cgi = shift;

    my @return;

    for my $search_by (@{ $cgi->{search_by} }) {
        if ($search_by =~ /\A(.*)=(.*)\z/) {
            my $field    = $1;
            my $operator = $2;

            # confirm operator and field is recognized
            unless (grep $operator eq $_, qw( ilike like eq ne lt gt le ge )) {
                IC::Exception::FeatureNotImplemented->throw( "Common list search operator: $operator" );
            }

            my $value = $cgi->{$field};
            if ($operator eq 'like' or $operator eq 'ilike') {
                $value = '%' . $cgi->{$field} . '%';
            }

            push @return, ( 
                $field => {
                    $operator => $value,
                },
            );
        }
    }

    return @return;
}

sub _goto_detail_form {
    my $self = shift;
    my $args = { @_ };
    
    my $_func_prefix = $self->_func_prefix;
    
    my %form_action_args;
    if (defined $args->{form_action_args}) {
        %form_action_args = %{ $args->{form_action_args} };
    }
    $args->{form_content} ||= 'Enter Specific ID #';

    #
    # TODO: make this a component
    #
    my @html;
    push @html, "<tr>\n";
    push @html, "<td class=\"list_table_" . (defined $args->{as_title} && $args->{as_title} ? 'title' : 'datum') . "_cell\"> $args->{form_content}: </td>\n";
    push @html, "<td class=\"list_table_datum_cell\">\n";
    push @html, "<form action=\"";
    push @html, $self->manage_function_uri(
        method => 'DetailView',
        %form_action_args,
    );
    push @html, "\">\n";
    push @html, "<input type=\"text\" name=\"_pk_id\" size=\"15\" maxlength=\"15\" />\n";
    push @html, "<input type=\"submit\" value=\"Submit\" />";
    push @html, "</form>\n";
    push @html, "<br />\n";
    push @html, "</td>\n";
    push @html, "</tr>\n";

    return @html;
}

#############################################################################
#
#
#
sub _common_list_display_all {
    my $self = shift;

    $self->_controller->parameters->{mode} = 'listall';

    # this in effect provides a vector to turn off paging via the URL
    # for normal common list or on for display all
    $self->_controller->parameters->{_paginate} = 0;

    $self->_step( 1 );

    return $self->_common_list(@_);
}

sub _common_list {
    my $self = shift;

    my $_model_class          = $self->_model_class;
    my $_model_class_mgr      = $self->_model_class_mgr;
    my $_object_name          = $self->_model_display_name;
    my $_plural_name          = $self->_model_display_name_plural;

    my $component_kind = 'generic';
    my $context        = {};

    my $title    = "List $_plural_name";
    my $subtitle = '';

    my $add_link = __PACKAGE__->manage_function_link(
        function   => $self->_func_prefix . 'Add',
        click_text => "[&nbsp;Add&nbsp;$_object_name&nbsp;]",
        controller => $self->_controller,
    );
    $subtitle .= $add_link;

    #
    # TODO: test this is correct
    #
    $context->{_manage_list_1_allow_filtering} = ! $self->_list_no_filter;

    if ($self->_step == 0) {
        $title .= '&nbsp;:&nbsp;Menu';

        #
        # TODO: make this a component
        #

        my $content = [];
        push @$content, "<table id=\"list_table\">";

        my $total = $_model_class_mgr->get_objects_count;
        if ($total) {
            if ($self->can('_list_0_hook')) {
                my $result = $self->_list_0_hook($content, \$subtitle);
                if ($result) {
                    # still need or throw exception from hook?
                    IC::Exception->throw( "Hook returned error: $result" );
                }
            }

            push @$content, "<tr>";
            push @$content, "<td class=\"list_table_title_cell\">List All</td>";
            push @$content, "<td class=\"list_table_datum_cell_centered\">";
            push @$content, $self->manage_function_link(
                step       => $self->_step + 1, 
                click_text => $total,
                query      => {
                    mode => 'listall',
                },
            );
            push @$content, "</td>";
            push @$content, "</tr>";

            if (defined $self->_list_status_field) {
                my $field       = $self->_list_status_field;
                my $key_method  = $self->_list_status_obj_key_method  || 'code';
                my $name_method = $self->_list_status_obj_name_method || 'display_label';

                push @$content, "<tr><td colspan=\"2\">&nbsp;</td></tr>";
                push @$content, "<tr>";
                push @$content, "<td class=\"list_table_title_cell\">List by Status</td>";
                push @$content, "<td class=\"list_table_title_cell_centered\">Count</td>";
                push @$content, "</tr>";
                for my $status_obj (@{ $self->_list_status_class->get_objects }) {
                    my $key  = $status_obj->$key_method;
                    my $name = $status_obj->$name_method;

                    my $count = $_model_class_mgr->get_objects_count( query => [ $field => $key ] );
                    if ($count) {
                        push @$content, "<tr>";
                        push @$content, "<td class=\"list_table_datum_cell\">";
                        push @$content, $self->manage_function_link(
                            step       => $self->_step + 1, 
                            click_text => $name,
                            query      => {
                                mode        => 'list',
                                'list_by[]' => $field,
                                $field      => $key,
                            },
                        );
                        push @$content, "</td>";
                        push @$content, "<td class=\"list_table_datum_cell_centered\">$count</td>";
                        push @$content, "</tr>";
                    }
                }
            }
            if (defined $self->_list_kind_field) {
                my $field       = $self->_list_kind_field;
                my $key_method  = $self->_list_kind_obj_key_method  || 'code';
                my $name_method = $self->_list_kind_obj_name_method || 'display_label';

                push @$content, "<tr><td colspan=\"2\">&nbsp;</td></tr>";
                push @$content, "<tr>";
                push @$content, "<td class=\"list_table_title_cell\">List by Kind</td>";
                push @$content, "<td class=\"list_table_title_cell_centered\">Count</td>";
                push @$content, "</tr>";
                for my $kind_obj (@{ $self->_list_kind_class->get_objects }) {
                    my $key  = $kind_obj->$key_method;
                    my $name = $kind_obj->$name_method;

                    my $count = $_model_class_mgr->get_objects_count( query => [ $field => $key ] );
                    if ($count) {
                        push @$content, "<tr>";
                        push @$content, "<td class=\"list_table_datum_cell\">";
                        push @$content, $self->manage_function_link(
                            step       => $self->_step + 1, 
                            click_text => $name,
                            query      => {
                                mode        => 'list',
                                'list_by[]' => $field,
                                $field      => $key,
                            },
                        );
                        push @$content, "</td>";
                        push @$content, "<td class=\"list_table_datum_cell_centered\">$count</td>";
                        push @$content, "</tr>";
                    }
                }
            }

            #
            # Old style status handling, this is mostly deprecated in favor of storing
            # the statuses in the DB, see lines above for _list_status_field
            #
            if ($_model_class->can('statuses')) {
                push @$content, "<tr><td colspan=\"2\">&nbsp;</td></tr>";
                push @$content, "<tr>";
                push @$content, "<td class=\"list_table_title_cell\">List by Status</td>";
                push @$content, "<td class=\"list_table_title_cell_centered\">Count</td>";
                push @$content, "</tr>";
                while (my ($key, $name) = each %{ $_model_class->statuses }) {
                    my $count = $_model_class_mgr->get_objects_count( query => [ status => $key ] );
                    if ($count) {
                        push @$content, "<tr>";
                        push @$content, "<td class=\"list_table_datum_cell\">";
                        push @$content, $self->manage_function_link(
                            step       => $self->_step + 1, 
                            click_text => $name,
                            query      => {
                                mode        => 'list',
                                'list_by[]' => 'status',
                                status      => $key,
                            },
                        );
                        push @$content, "</td>";
                        push @$content, "<td class=\"list_table_datum_cell_centered\">$count</td>";
                        push @$content, "</tr>";
                    }
                }
            }

        }
        else {
            push @$content, "<tr><td class=\"list_table_datum_cell\">No " . lc $_plural_name . " to list.</td></tr>\n";
        }
        push @$content, "</table>\n";

        $context->{body} = join '', @$content;
    }
    elsif ($self->_step == 1) {
        my $params = $self->_controller->parameters;

        unless (defined $params->{mode} and $params->{mode} ne '') {
            IC::Exception::MissingValue->throw( 'mode' );
        }

        my $step0_list_link = $self->manage_function_link(
            method     => 'List',
            click_text => "[&nbsp;Up&nbsp;]",
            role       => $self->_controller->role,
        );
        if (defined $step0_list_link) {
            $subtitle .= $step0_list_link;
        }

        my $query = [];
        if (lc $params->{mode} eq 'list') {
            unless (defined $params->{list_by} and $params->{list_by} ne '') {
                IC::Exception::MissingValue->throw( 'Missing parameter for mode "list": list_by[]' );
            }

            my @parts;
            for my $list_by (@{ $params->{list_by} }) {
                my $display_value = '';
                if (defined $params->{$list_by} and $params->{$list_by} ne '') {
                    if (ref $params->{$list_by} eq 'ARRAY') {
                        push @$query, $list_by => $params->{$list_by};
                        $display_value = join ', ', @{ $params->{$list_by} };
                    }
                    else {
                        push @$query, $list_by => $params->{$list_by};
                        $display_value = $params->{$list_by};
                    }
                }
                else {
                    for my $field (@{ $_model_class->meta->columns }) {
                        next unless $field eq $list_by;

                        if (grep { $field->type eq $_ } qw( date datetime time timestamp numeric integer )) {
                            push @$query, $list_by => undef;
                            $display_value = '&lt;undef&gt;';
                        }
                        else {
                            push @$query, $list_by => [ '', undef ];
                            $display_value = '&lt;undef&gt; or &lt;empty&gt;';
                        }
                    }
                }

                if ($list_by eq 'status_code') {
                    push @parts, "Status = $display_value";
                }
                elsif ($list_by eq 'kind_code') {
                    push @parts, "Kind = $display_value";
                }
                else {
                    #
                    # TODO: check for how we handle filters
                    #
                    push @parts, $::Tag->filter('pretty_field_name_html', $list_by) . "&nbsp;=&nbsp;$display_value";
                }
            }

            $title .= ' : By ' . join ', ', @parts;
        }
        elsif (lc $params->{mode} eq 'search') {
            # search_by holds the search specification, which is required
            unless (defined $params->{search_by} and $params->{search_by} ne '') {
                IC::Exception::MissingValue->throw( 'search_by' );
            }

            push @$query, $self->_process_search_by( $params );

            $title .= ' : By Search';
        }
        elsif (lc $params->{mode} eq 'listall') {
            # listing all objects so no query parameters
            $title .= ' : All';
        }
        else {
            IC::Exception->throw( "Unrecognized mode: $params->{mode}" );
        }

        my $total = $_model_class_mgr->get_objects_count( query => $query );
        if ($total) {
            my $prefix = $self->_func_prefix;

            my @pk_fields  = @{ $_model_class->meta->primary_key_columns };

            if (defined $params->{_paginate} and not $params->{_paginate}) {
                $context->{page_count} = $self->_list_page_count;
            }
            else {
                $context->{page_count} = $self->_list_page_count || 25;
            }

            my $_list_cols = $self->_list_cols;

            my ($headers, $fields) = ([] , []);
            for my $col (@$_list_cols) {
                push @$fields, $col->{method};
                push @$headers, {
                    method    => $col->{method},
                    display   => $col->{display},
                    class_opt => $col->{class_opt},
                };
            }
            $context->{headers} = $headers;
            $context->{fields}  = $fields;

            my $functions = { 
                $prefix.'Properties' => { display => 'Edit' },
                $prefix.'Drop'       => { display => 'Drop' },
                $prefix.'DetailView' => { display => 'Detail' },
            };

            for (@{ $self->_list_additional_functions }) {
                $functions->{$prefix . $_->{type}} = { display => $_->{display} };
            }

            my $list = [];
            for my $object (@{ $_model_class_mgr->get_objects( query => $query ) }) {
                my $details = {};
                push @$list, $details;

                for my $col (@$_list_cols) {
                    no strict 'refs';
                    my $method = $col->{method};

                    # force stringification
                    my $value = $object->$method();
                    $details->{ $col->{method} } = "$value";

                    $details->{ "$col->{method}\_class_opt" } = $col->{class_opt};
                }

                my %_pk_params = map { '_pk_'.$_ => $object->$_() } @pk_fields;

                my $details_functions = [];
                for my $key (qw(DetailView Properties Drop), map { $_->{type} } @{ $self->_list_additional_functions }) {
                    my $name = "$prefix$key";
                    push @$details_functions, __PACKAGE__->manage_function_link(
                        function   => $name,
                        query      => {
                            %_pk_params,
                        },
                        click_text => "[&nbsp;$functions->{$name}->{display}&nbsp;]",
                        controller => $self->_controller,
                    );
                }
                $details->{function_options} = $details_functions;
            }
            if (@$list) {
                $context->{rows} = $list;
            }

            $context->{list_class} = ref $self;

            $component_kind = 'list_paginated';
        }
        else {
            $context->{body} = "No $_plural_name to list.";
        }
    }
    else {
        IC::Exception->throw( "common list: unrecognized step" );
    }

    $self->set_title( $title );
    $self->set_subtitle( $subtitle );

    $self->set_response(
        type    => 'component',
        kind    => $component_kind,
        context => $context,
    );

    return;
}

sub _common_list_data_obj {
    my $self = shift;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;

    my $params = $self->_controller->parameters;

    my $struct;
    if ($self->_step == 0) {
        if ($params->{_mode} eq 'config') {
            $struct = {
                model_name        => $self->_model_display_name,
                model_name_plural => $self->_model_display_name_plural,
                total_objects     => $_model_class_mgr->get_objects_count,
                paging_provider   => $self->_list_paging_provider,
                page_count        => $self->_list_page_count,
                row_actions       => [],
            };

            my $_list_cols = $self->_list_cols;
            for my $col (@$_list_cols) {
                push @{ $struct->{data_source_fields} }, {
                    key    => $col->{method},
                    parser => $col->{parser},
                };

                my $def_list_key = 'data_table_column_defs';
                if (defined $col->{is_initially_hidden} and $col->{is_initially_hidden}) {
                    $def_list_key = 'data_table_hidden_column_defs';
                }

                push @{ $struct->{$def_list_key} }, {
                    key       => $col->{method},
                    label     => $col->{display},

                    # assume the best
                    sortable  => (defined $col->{sortable} ? $col->{sortable} : 1),
                    resizable => (defined $col->{resizable} ? $col->{resizable} : 1),

                    (defined $col->{formatter} ? (formatter => $col->{formatter}) : ()),
                    #class_opt => $col->{class_opt},
                };

                if (defined $col->{is_default_sort} and $col->{is_default_sort}) {
                    $struct->{data_table_initial_sort} = {
                        key => $col->{method},
                        dir => $col->{default_sort_direction} || 'asc',
                    };
                }
            }

            # every row gets a set of options at least until we add privilege checking
            # or better action handling
            push @{ $struct->{data_source_fields} }, {
                key => '_options',
            };
            push @{ $struct->{data_table_column_defs} }, {
                key       => '_options',
                label     => 'Options',
                sortable  => 0,
                resizable => 0,
            };

            my $prefix = $self->_func_prefix;
            my $functions = [ 
                {
                    code    => $prefix.'Properties',
                    display => 'Edit',
                },
                {
                    code    => $prefix.'Drop',
                    display => 'Drop',
                },
                {
                    code    => $prefix.'DetailView',
                    display => 'Detail',
                },
            ];
            for my $func (@$functions) {
                # TODO: add privilege check, etc.
                push @{ $struct->{row_actions} }, $func;
            }
        }
        elsif ($params->{_mode} eq 'data') {
            $params->{filter_mode} ||= 'listall';

            my $get_objects_config = {};

            my $query = [];
            if (lc $params->{filter_mode} eq 'list') {
                unless (defined $params->{list_by} and $params->{list_by} ne '') {
                    IC::Exception::MissingValue->throw( 'Missing parameter for filter mode "list": list_by[]' );
                }

                for my $list_by (@{ $params->{list_by} }) {
                    if (defined $params->{$list_by} and $params->{$list_by} ne '') {
                        if (ref $params->{$list_by} eq 'ARRAY') {
                            push @$query, $list_by => $params->{$list_by};
                        }
                        else {
                            push @$query, $list_by => $params->{$list_by};
                        }
                    }
                    else {
                        for my $field (@{ $_model_class->meta->columns }) {
                            next unless $field eq $list_by;

                            if (grep { $field->type eq $_ } qw( date datetime time timestamp numeric integer )) {
                                push @$query, $list_by => undef;
                            }
                            else {
                                push @$query, $list_by => [ '', undef ];
                            }
                        }
                    }
                }
            }
            elsif (lc $params->{filter_mode} eq 'search') {
                # search_by holds the search specification, which is required
                unless (defined $params->{search_by} and $params->{search_by} ne '') {
                    IC::Exception::MissingValue->throw( 'Missing parameter for filter mode "search": search_by[]' );
                }

                push @$query, $self->_process_search_by( $params );
            }
            elsif (lc $params->{filter_mode} eq 'listall') {
                # listing all objects so no query parameters
            }
            else {
                IC::Exception->throw( "Unrecognized filter mode: $params->{filter_mode}" );
            }

            if ($query) {
                $get_objects_config->{query} = $query;
            }

            # TODO: should this move until after param parsing, at least everything but sort?
            #
            # for the data table + paging we need a total count of records each time, I'm not sure why
            # if we add caching this is something that can be cached easily
            $struct->{total_objects} = $_model_class_mgr->get_objects_count(%$get_objects_config);

            # this is the key into the cols, not necessarily what to sort on
            my $found_sort_col;
            my $sort_key;
            my $add_desc = 0;
            if (defined $params->{sort}) {
                for my $col (@{ $self->_list_cols }) {
                    next unless $col->{method} eq $params->{sort};

                    $found_sort_col = $col;
                    last;
                }
                unless (defined $found_sort_col) {
                    warn "Attempt to sort on '$params->{sort}' but found no matching column (" . $self->_function . ")";
                }
                if (defined $params->{dir} and $params->{dir} eq 'desc') {
                    $add_desc = 1;
                }
            }
            else {
                # no sort passed, check our list of columns for the default to use
                for my $col (@{ $self->_list_cols }) {
                    next unless defined $col->{is_default_sort};

                    $found_sort_col = $col;
                    $add_desc = 1 if (defined $col->{default_sort_direction} and $col->{default_sort_direction} eq 'desc');

                    last;
                }
            }
            if (defined $found_sort_col) {
                if (defined $found_sort_col->{sort_sql_clause}) {
                    # needs to be a scalar ref to get passed through unmolested by RDBO
                    IC::Exception->throw('Invalid value type (sort_sql_clause): not a scalar ref') unless ref $found_sort_col->{sort_sql_clause} eq 'SCALAR';

                    $get_objects_config->{sort_by} = $found_sort_col->{sort_sql_clause};
                }
                else {
                    $get_objects_config->{sort_by} = $found_sort_col->{method};
                }
                $sort_key = $get_objects_config->{sort_by};
                if ($add_desc) {
                    if (ref $get_objects_config->{sort_by} eq 'SCALAR') {
                        ${ $get_objects_config->{sort_by} } .= ' DESC'
                    }
                    else {
                        $get_objects_config->{sort_by} .= ' DESC'
                    }
                }
            }

            if ($self->_list_paging_provider eq 'server') {
                $get_objects_config->{offset} = $params->{startIndex} || 0;
                $struct->{startIndex}         = $get_objects_config->{offset};

                $get_objects_config->{limit}  = $params->{results} || $self->_list_page_count;
                $struct->{results}            = $get_objects_config->{limit};
                $struct->{sort}               = $sort_key;
                $struct->{dir}                = $add_desc ? 'desc' : 'asc';
            }

            # TODO: this could be done on the client side via a formatter
            my $prefix = $self->_func_prefix;
            my $functions = [ 
                {
                    code    => $prefix.'DetailView',
                    display => 'Detail',
                },
            ];

            for my $object (@{ $_model_class_mgr->get_objects( %$get_objects_config ) }) {
                my $details = {};

                for my $col (@{ $self->_list_cols }) {
                    #no strict 'refs';
                    my $method = $col->{method};

                    my $value = $object->$method();
                    $details->{ $method } = "$value";
                }

                my $_options = '';
                for my $func (@$functions) {
                    # TODO: add privilege check, etc.
                    my $object_pk = join '&', map { "_pk_$_=" . $object->$_ } @{ $object->meta->primary_key_columns };
                    my $link = qq|<a id="manage_menu_item-function-detail-$func->{code}-$object_pk" class="manage_function_link">$func->{display}</a> |;
                    $_options .= $link;
                }
                $details->{_options} = $_options;

                push @{ $struct->{rows} }, $details;
            }
        }
        else {
            IC::Exception->throw("Unrecognized _mode: $params->{_mode}");
        }
    }
    else {
        IC::Exception->throw('Unrecognized step: ' . $self->_step);
    }

    if ($params->{_format} eq 'json') {
        my $response = $self->_controller->response;
        $response->headers->status('200 OK');
        $response->headers->content_type('text/plain');
        #$response->headers->content_type('application/json');
        $response->buffer( JSON::Syck::Dump( $struct ));

        $self->_response(1);
    }
    else {
        IC::Exception->throw("Unrecognized _format: $params->{_format}");
    }

    return;
}

# DO NOT COMMIT
#*_common_list_display_all = \&IC::Manage::_common_list_data_obj;
#*_common_list             = \&IC::Manage::_common_list_data_obj;
#*_common_detail_view      = \&IC::Manage::_common_detail_data_obj;
#*_common_properties       = \&IC::Manage::_common_properties_data_obj;

sub _common_add {
    my $self = shift;

    $self->_controller->parameters->{_properties_mode} = 'add';

    my $sub = $self->_sub_prefix.'Properties';
    return $self->$sub(@_);
}

sub _common_properties {
    my $self = shift;
    my %args = @_;

    $args{addtl_titles} ||= [];

    my $params = $self->_controller->parameters;
    $params->{_properties_mode} ||= 'edit';

    if ($params->{_properties_mode} eq 'upload') {
        return $self->_common_properties_upload;
    }
    if ($params->{_properties_mode} eq 'unlink') {
        $self->_common_properties_unlink;
        return;
    }

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;
    my @fields     = @{ $_model_class->meta->columns };

    if ($self->_step == 0) {
        my $context = {
            provided_form    => 0,
            form_include     => $self->_function . '-' . $self->_step,
            form_referer     => $ENV{HTTP_REFERER},
            _function        => $self->_function,
            _step            => $self->_step + 1,
            _properties_mode => $params->{_properties_mode},
        };
        my $form_values     = $context->{f}               = {};
        my $include_options = $context->{include_options} = {};

        my %hook_params = ( context => $context );
        if ($params->{_properties_mode} eq 'edit') {
            my $object = $self->_common_implied_object;

            $self->set_title("Edit $_object_name Properties", $object, @{ $args{addtl_titles} });

            for my $field (@fields) {
                # this is irritating, and necessary because IC eats "id" parameters
                if ($field eq 'id') {
                    $form_values->{_work_around_ic_id} = $object->$field;
                }
                else {
                    $form_values->{$field} = $object->$field;
                }
            }
            for my $_pk_field (@_pk_fields) {
                $context->{pk_pairs}->{$_pk_field} = $params->{$_pk_field};
            }

            $hook_params{object} = $object;
        }
        else {
            $self->set_title("Add $_object_name");

            for my $field (@fields) {
                $form_values->{$field} = $params->{$field} if defined $params->{$field};
            }

            #
            # originally didn't want to make this smart, but I've
            # since decided that creating the symlink every time
            # we need an add doesn't make sense, so making this
            # smart to recognize when Add exists to use it, otherwise
            # fall back to Properties
            #

            #
            # TODO: make this configurable per class
            #
            my $path = File::Spec->catfile(
                #
                # TODO: depending on how things fall out this may be better
                #       situated as a link under the deployment path
                #
                IC::Config->catalog_path,
                "views/components/manage/function/form/$context->{form_include}.tst",
            );
            unless (-e $path) {
                $context->{form_include} = $self->_func_prefix . 'Properties-' . $self->_step;
            }
        }

        if ($self->can('_properties_form_hook')) {
            $self->_properties_form_hook(%hook_params);
        }

        $self->set_response(
            type    => 'component',
            kind    => 'form',
            context => $context,
        );
    }
    elsif ($self->_step == 1) {
        # start a transaction, need this so that things
        # happening in the hooks will be within
        # the same transaction, in case of an exception
        my $db = $_model_class->init_db;
        $db->begin_work;

        my $result = $self->_properties_action_hook( db => $db );
        if ($result) {
            # TODO: have the properties action hook handle the profile
            #       processing of old, since we are no longer in a FormAction
            #       so need to have a return that will redirect back to
            #       where we were
        }

        if (defined $params->{_work_around_ic_id} and $params->{_work_around_ic_id} ne '') {
            $params->{id} = $params->{_work_around_ic_id};
        }

        my %obj_params;
        for my $field (@fields) {
            next unless defined $params->{$field};
            next if grep { $field eq $_ } qw( date_created last_modified created_by modified_by );

            $obj_params{$field} = $params->{$field};
        }
        $obj_params{modified_by} = $self->_controller->role->id;

        for my $field (@fields) {
            next if grep { $field eq $_ } qw( date_created last_modified );

            # clear empty dates so they become a NULL
            if (grep { $field->type eq $_ } qw( date datetime time timestamp numeric )) {
                if ("$obj_params{$field}" eq '') {
                    $obj_params{$field} = undef;
                }
            }
        }

        my $object;
        if ($params->{_properties_mode} eq 'edit') {
            my %pk_params;
            for my $_pk_field (@_pk_fields) {
                my ($key, $val) = ($_pk_field, $params->{$_pk_field});
                $key =~ s/^_pk_//;

                $pk_params{$key} = $val;
            }

            # TODO: do we still need to do things this way?
            my $num_rows_updated = $_model_class_mgr->update_objects(
                db    => $db,
                set   => { %obj_params },
                where => [ %pk_params ],
            );
            unless ($num_rows_updated > 0) {
                IC::Exception->throw( 'Unable to update record based on PK values.' );
            }
            if ($num_rows_updated > 1) {
                IC::Exception->throw( 'Multiple rows updated when single primary key should match. SPEAK TO DEVELOPER!' );
            }

            my %new_pk_params;
            for my $field (@pk_fields) {
                $new_pk_params{$field} = $obj_params{$field};
            }

            # instantiate the object with new primary key a) to make
            # sure everything is good, b) to use the object to redirect
            # to the new detail record

            # TODO: set a message that the record was updated
            #       to be displayed on the detail view

            $object = $_model_class->new(
                db => $db,
                %new_pk_params,
            )->load;
        }
        elsif ($params->{_properties_mode} eq 'add') {
            $obj_params{created_by} = $self->_controller->role->id;

            $object = $_model_class->new(
                db => $db,
                %obj_params,
            );
            unless ($object) {
                IC::Exception::ModelInstantiateFailure->throw( $_object_name );
            }
            $object->save;

            # TODO: set a message that the record was created
            #       to be displayed on the detail view
            
            # see if this load is needed when adding
            $object->load;
        }
        else {
            IC::Exception->throw( "Unrecognized properties mode: $params->{_properties_mode}" );
        }

        # TODO: verify in new framework
        if ($self->can('_properties_post_action_hook')) {
            $self->_properties_post_action_hook($object);
        }

        $db->commit;

        unless ($self->_properties_referrer_no_override) {
            my $detail_url = $self->_object_manage_function_link( 'DetailView', $object, url_only => 1 );
            if ($detail_url) {
                $params->{redirect_referer} = $detail_url;
            }
        }

        $self->_referer_redirect_response;

        return;
    }
    else {
        IC::Exception->throw( "Unrecognized step: " . $self->_step );
    }

    return;
}

#
#
#
sub _common_properties_data_obj {
    my $self = shift;

    my $params = $self->_controller->parameters;
    $params->{_format} ||= 'json';

    my $_model_class = $self->_model_class;
    my $_object_name = $self->_model_display_name;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields   = map { "_pk_$_" } @pk_fields;

    my $struct;

    #
    # everything but 'add' should be working against an existing object,
    # and to do so we need to be able to distinguish it using the existing
    # PK, so get the fields for the PK and store the corresponding values,
    # which we know to be passed in via the request and already stringified
    #
    my $object;
    unless ($params->{_properties_mode} eq 'add') {
        $object = $self->_common_implied_object;

        for my $_pk_field (@_pk_fields) {
            $struct->{pk_pairs}->{$_pk_field} = $params->{$_pk_field};
        }
    }

    # TODO: make these a dispatch table?
    if ($params->{_properties_mode} eq 'edit' or $params->{_properties_mode} eq 'add') {
        #
        # get the fields in the object, loop over them determining which fields need to be 
        # or may have been included in the form
        #
        my @fields = @{ $_model_class->meta->columns };

        #
        # boilerplate fields by their nature are automatically handled, therefore they aren't
        # editable
        #
        my @boilerplate_fields = keys %{ { $_model_class->boilerplate_columns } };

        #
        # get the structure used to override default behaviour for the fields,
        # it is keyed by DB field name
        #
        my $form_adjustments = $self->_properties_form_adjustments || {};

        #
        # cache look up of field meta data objects by name of field for easy access
        #
        my $rdbo_fields_by_name = {};

        #
        # need to pre-process fields to build a sort order and remove any fields not intended 
        # to be included, we'll just go with the sort order of what RDBO has for any non-specified 
        # fields, therefore all specified fields will sort first, included fields also determines
        # which fields we'll be allowed to set new values for
        #
        my @included_fields;

        my $highest_provided_sort_order = 0;
        for my $field (@fields) {
            # skip the boilerplate fields
            next if grep { $field eq $_ } @boilerplate_fields;

            my $field_name = $field->name;
            my $adjust     = $form_adjustments->{$field_name} || {};

            # skip fields explicitly turned off, this is called 'included' because even things
            # that are not editable and/or hidden should still be included in this list, these
            # things that we aren't even going to have in the meta data. period.

            next if (defined $adjust->{is_included} and not $adjust->{is_included});
            next if ($params->{_properties_mode} eq 'edit' and defined $adjust->{is_included_in_edit} and not $adjust->{is_included_in_edit});
            next if ($params->{_properties_mode} eq 'add' and defined $adjust->{is_included_in_add} and not $adjust->{is_included_in_add});

            push @included_fields, $field_name;
            $rdbo_fields_by_name->{ $field_name } = $field;

            if (defined $adjust->{order} and $adjust->{order} > $highest_provided_sort_order) {
                $highest_provided_sort_order = $adjust->{order} + 1;
            }
        }

        #
        # assign an order to all non-ordered fields starting with the value as determined above
        #
        for my $included_field (@included_fields) {
            next if defined $form_adjustments->{$included_field}->{order};

            $form_adjustments->{$included_field}->{order} = $highest_provided_sort_order;
            ++$highest_provided_sort_order;
        }

        if ($params->{_mode} eq 'config') {
            my @form_fields;
            for my $field (sort { $form_adjustments->{$a}->{order} <=> $form_adjustments->{$b}->{order} } @included_fields) {
                my $adjust = $form_adjustments->{$field};

                my $label;
                if (defined $adjust->{label}) {
                    $label = $adjust->{label};
                }
                else {
                    $label = join ' ', map { $_ eq 'id' ? 'ID' : ucfirst } split /_/, $field;
                }

                my $field_ref = {
                    _method => $field,
                    label   => $label,
                };

                #
                # a value in 'field_type' for the field_ref is what determines whether we consider
                # the field "editable" (even if it is going to be hidden), otherwise it won't
                # appear in the form as an input and therefore won't exist in the store request,
                # in that case it is just being displayed for reference purposes
                #
                unless (defined $adjust->{field_type}) {
                    # TODO: give date, time, datetime, timestamp multiple fields, or can be done with
                    #       one field type that is rendered using multiple client side fields?

                    #
                    # by default we make single field PKs that are integers with the name 'id'
                    # not be editable, this can be overridden by specifying an is_editable adjustment
                    #
                    if (not defined $adjust->{is_editable} 
                        and $field eq 'id' 
                        and @pk_fields == 1 
                        and $rdbo_fields_by_name->{$field}->type eq 'serial'
                    ) {
                        $adjust->{is_editable} = 0;
                    }

                    #
                    # set a default field type unless the value isn't editable in which case
                    # we should just display the current value as a reference (otherwise it 
                    # can be turned off by using is_included above)
                    #
                    unless (defined $adjust->{is_editable} and not $adjust->{is_editable}) {
                        # TODO: add auto handling of FK relationships when it is trivial to handle them

                        if ($rdbo_fields_by_name->{$field}->type eq 'text') {
                            $adjust->{field_type} = 'TextareaField';
                        }
                        elsif ($rdbo_fields_by_name->{$field}->type eq 'boolean') {
                            $adjust->{field_type} = 'RadioField';
                        }
                        elsif ($rdbo_fields_by_name->{$field}->type eq 'date') {
                            $adjust->{has_validator} = 'date';
                        }
                        elsif ($rdbo_fields_by_name->{$field}->type eq 'time') {
                            $adjust->{has_validator} = 'time';
                        }
                        else {
                            $adjust->{field_type} = 'TextField';
                        }
                    }
                }

                #
                # if the field type is specified then we expect there to be a control in the form
                # to match this field so set its name and do anything else the particular type requires
                #
                if (defined $adjust->{field_type}) {
                    $field_ref->{type} = $adjust->{field_type};
                    $field_ref->{name} = $field;

                    # this is irritating, and necessary because IC eats "id" parameters
                    if ($field eq 'id') {
                        $field_ref->{name} = '_work_around_ic_id';
                    }

                    # see if a value already exists in our request, if so, maintain it
                    if (defined $params->{$field_ref->{name}}) {
                        $field_ref->{value} = $params->{$field_ref->{name}};
                    }

                    if (grep { $field_ref->{type} eq $_ } qw( CheckboxField RadioField SelectField )) {
                        if (defined $adjust->{get_choices}) {
                            $field_ref->{choices} = $adjust->{get_choices}->($self);
                        }
                        elsif ($field_ref->{type} eq 'RadioField' and $rdbo_fields_by_name->{$field}->type eq 'boolean') {
                            $field_ref->{choices} = [
                                {
                                    value => 1,
                                    label => 'Yes',
                                },
                                {
                                    value => 0,
                                    label => 'No',
                                },
                            ];
                        }
                        else {
                            $field_ref->{choices} = [];
                        }
                    }
                }
                if (defined $adjust->{has_validator}) {
                    $field_ref->{validator} = $adjust->{has_validator};
                }

                push @form_fields, $field_ref;
            }
            $struct->{form_fields} = \@form_fields;

            my $button_field = {
                type  => 'submit',
                label => 'Submit',
            };
            $struct->{button_field} = $button_field;

            my $title;
            if ($params->{_properties_mode} eq 'edit') {
                $title = "Edit $_object_name Properties : " . $object->manage_description;
                $button_field->{label} = 'Save Changes';

                for my $field_ref (@form_fields) {
                    next if defined $field_ref->{value};

                    my $method = $field_ref->{_method};
                    if (defined $object->$method) {
                        $field_ref->{value} = $object->$method . '';
                    }
                }
            }
            else {
                $title = "Add $_object_name";
            }

            $struct->{title} = $title;

            if ($self->can('_properties_edit_config_hook')) {
                $self->_properties_edit_config_hook($struct, $object);
            }
        }
        elsif ($params->{_mode} eq 'store') {
            #
            # catch all exceptions so that we can respond with an exception
            # to be displayed in the form
            #
            eval {
                #
                # TODO: add back in pre-hook processing
                #

                #
                # TODO: if we use individual hooks that can be set in each field
                #       can we remove the need for generic hooks, see 'undef_on_add'
                #       and/or example of server side validation on field basis
                #

                if ($params->{_properties_mode} eq 'edit') {
                    for my $field (sort { $form_adjustments->{$a}->{order} <=> $form_adjustments->{$b}->{order} } @included_fields) {
                        my $param_name = $field;
                        if ($field eq 'id') {
                            $param_name = '_work_around_ic_id';
                        }

                        #
                        # TODO: restore handling of switching date/numeric fields to undef, etc.
                        #

                        $object->$field($params->{$param_name});
                    }
                }
                else {
                    # TODO: instantiate object
                    # TODO: implement calling undef_on_add dispatch for setting "default" values
                }
                $object->save;

                #
                # TODO: add back in post-hook processing
                #
            };
            if ($@) {
                $struct->{response_code} = 0;
                $struct->{exception} = $@;
            }
            else {
                $struct->{response_code} = 1;
            }
        }
        else {
            IC::Exception->throw("Unrecognized _mode for '$params->{_properties_mode}' _properties_mode: $params->{_mode}");
        }
    }
    elsif ($params->{_properties_mode} eq 'upload') {
    }
    elsif ($params->{_properties_mode} eq 'unlink') {
    }
    else {
        IC::Exception->throw("Unrecognized _properties_mode: $params->{_properties_mode}");
    }

    if ($params->{_format} eq 'json') {
        my $response = $self->_controller->response;
        $response->headers->status('200 OK');
        $response->headers->content_type('text/plain');
        #$response->headers->content_type('application/json');
        $response->buffer( JSON::Syck::Dump( $struct ));

        $self->_response(1);
    }
    else {
        IC::Exception->throw("Unrecognized _format: $params->{_format}");
    }

    return;
}

sub _common_properties_upload {
    my $self = shift;

    my $params = $self->_controller->parameters;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    my $object = $self->_common_implied_object;

    # TODO: this needs to be improved to handle tree structure specification of resource handle
    unless (defined $params->{resource} and $params->{resource} ne '') {
        IC::Exception->throw('Required argument missing: resource');
    }

    my $attr_refs;

    my $file_resource_obj = $self->_file_resource_class->new(
        id => $params->{resource},
    );
    unless ($file_resource_obj->load( speculative => 1 )) {
        IC::Exception->throw("Can't load file resource obj: $params->{resource}");
    }

    my $attrs = $file_resource_obj->attrs;
    if (@$attrs) {
        $attr_refs = [];

        my $properties;

        my $file = $file_resource_obj->get_file_for_object( $object );
        if (defined $file) {
            $properties = $file->properties;
        }

        for my $attr (@$attrs) {
            my $ref = {
                id            => $attr->id,
                code          => $attr->code,
                kind          => $attr->kind_code,
                display_label => $attr->display_label,
            };

            if ($self->_step == 0) {
                if (defined $properties) {
                    for my $property (@$properties) {
                        if ($property->file_resource_attr_id == $attr->id) {
                            $ref->{value} = $property->value;
                            last;
                        }
                    }
                }
            }
            elsif ($self->_step == 1 or $self->_step == 2) {
                # retrieve attribute value from CGI space
                $ref->{value} = $params->{'_attr_' . $attr->id};
            }

            push @$attr_refs, $ref;
        }
    }

    my $context         = {};
    my $form_values     = $context->{f}               = { resource => $params->{resource} };
    my $include_options = $context->{include_options} = {};

    if ($self->_step == 0 or $self->_step == 1) {
        $context->{provided_form}    = 0;
        $context->{form_include}     = '_common_properties_upload-' . $self->_step;
        $context->{_function}        = $self->_function;
        $context->{_step}            = $self->_step + 1;
        $context->{_properties_mode} = $params->{_properties_mode};

        for my $_pk_field (@_pk_fields) {
            $context->{pk_pairs}->{$_pk_field} = $params->{$_pk_field};
        }

        if (defined $attr_refs) {
            $include_options->{attributes} = $attr_refs;
        }
    }

    my $temporary_relative_path;
    my $temporary_path;
    if ($self->_step == 1 or $self->_step == 2) {
        $temporary_relative_path = File::Spec->catfile(
            'uncontrolled',
            '_manage_properties_upload',
            $object->meta->table,
            $object->serialize_pk,
            $file_resource_obj->sub_path( '_manage_properties_upload' ),
        );
        $temporary_path = File::Spec->catfile(
            $self->_file_class->_htdocs_path,
            $temporary_relative_path,
        );
    }

    if ($self->_step == 0) {
        #
        # TODO: check resource is required, already has file, has children descendents, etc.
        #
        $self->set_title("Upload $_object_name File ($params->{resource})", $object);

        $context->{form_enctype} = 'multipart/form-data';
        $context->{form_referer} = $ENV{HTTP_REFERER};

        if ($self->can('_properties_upload_form_hook')) {
            $self->_properties_upload_form_hook(
                object            => $object,
                file_resource_obj => $file_resource_obj,
                context           => $context,
            );
        }
    }
    elsif ($self->_step == 1) {
        $context->{form_referer} = $params->{redirect_referer};

        #
        # TODO: how do we get this in the new MVC framework?
        #
        my $file_contents = $::Tag->value_extended(
            {
                name          => 'uploaded_file',
                file_contents => 1,
            },
        );
        unless (length $file_contents) {
            IC::Exception->throw('File has no contents');
        }

        my $contents_io = IO::Scalar->new(\$file_contents);
        my $mime_type   = File::MimeInfo::Magic::magic($contents_io);
        unless ($mime_type ne '') {
            IC::Exception->throw('Unable to determine MIME type from file contents');
        }
        my $extension   = File::MimeInfo::extensions($mime_type);
        unless ($extension ne '') {
            IC::Exception->throw("Unable to determine file extension from mimetype: $mime_type");
        }

        my $temporary_filename      = "tmp.$$.$extension";
        my $temporary_file          = File::Spec->catfile($temporary_path, $temporary_filename);
        my $temporary_relative_file = File::Spec->catfile($temporary_relative_path, $temporary_filename);

        $form_values->{tmp_filename} = $temporary_filename;

        umask 0002;

        File::Path::mkpath($temporary_path);

        open my $OUTFILE, ">$temporary_file" or die "Can't open file for writing: $!\n";
        binmode $OUTFILE;
        print $OUTFILE $file_contents;
        close $OUTFILE or die "Can't close written file: $!\n";

        if ($mime_type =~ /\Aimage/) {
            $include_options->{upload_confirm_file} = qq{<img src="/$temporary_relative_file" />};
        }
        else {
            $include_options->{upload_confirm_file} = qq{<a href="/$temporary_relative_file"><img src="} . $self->_icon_path . q{" /></a>};
        }

        # store the attribute refs to the session for retrieval in step 2 for storage to the DB
        if (defined $attr_refs) {
            my $attr_values = {};
            for my $attr_ref (@$attr_refs) {
                $attr_values->{$attr_ref->{id}} = $attr_ref->{value};
            }

            $include_options->{upload_confirm_attrs} = $attr_values;
        }

        # TODO: need to walk children determining which need to be generated, etc.
        #       and provide back a list to allow them to choose to have them override
    }
    elsif ($self->_step == 2) {
        unless (defined $params->{tmp_filename} and $params->{tmp_filename} ne '') {
            IC::Exception->throw('Required argument missing: tmp_filename');
        }

        my $tmp_filename_extension;
        if ($params->{tmp_filename} =~ /\A.+\.\d+\.(.+)\z/) {
            $tmp_filename_extension = $1;
        }
        else {
            IC::Exception->throw("Unable to determine file extension from temporary filename: $params->{tmp_filename}");
        }

        my $db = $object->db;
        eval {
            $db->begin_work;

            my $user_id        = $self->_controller->role->id;
            my $temporary_file = File::Spec->catfile($temporary_path, $params->{tmp_filename});
            my $mime_type      = File::MimeInfo::Magic::magic($temporary_file);
            my $is_image       = $mime_type =~ /\Aimage/ ? 1 : 0;

            my $file = $file_resource_obj->get_file_for_object( $object );
            if (defined $file) {
                $file->modified_by( $user_id );
                $file->save;
            }
            else {
                $file_resource_obj->add_files(
                    {
                        db          => $db,
                        object_pk   => $object->serialize_pk,
                        created_by  => $user_id,
                        modified_by => $user_id,
                    },
                );
                $file_resource_obj->save;

                $file = $file_resource_obj->get_file_for_object( $object );
            }

            if (defined $attr_refs) {
                # TODO: make this more advanced to do updates when possible

                my $new_properties = [];
                for my $attr_ref (@$attr_refs) {
                    if (($attr_ref->{code} eq 'width' or $attr_ref->{code} eq 'height') and $is_image) {
                        next if $attr_ref->{value} eq '';
                    }
                    push @$new_properties, {
                        file_resource_attr_id => $attr_ref->{id},
                        value                 => $attr_ref->{value} || '',
                        created_by            => $user_id,
                        modified_by           => $user_id,
                    };
                }
                $file->properties($new_properties);
                $file->save;
            }

            $file->store( $temporary_file, extension => $tmp_filename_extension );
        };
        if ($@) {
            my $exception = $@;

            $db->rollback;

            die $exception;
        }

        $db->commit;

        $self->_referer_redirect_response;

        return;
    }
    else {
        IC::Exception->throw( 'Unrecognized step: ' . $self->_step );
    }

    $self->set_response(
        type    => 'component',
        kind    => 'form',
        context => $context,
    );

    return;
}

sub _common_properties_unlink {
    my $self = shift;

    my $params = $self->_controller->parameters;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    my $object = $self->_common_implied_object;

    # TODO: this needs to be improved to handle tree structure specification of resource handle
    unless (defined $params->{resource} and $params->{resource} ne '') {
        IC::Exception->throw('Required argument missing: resource');
    }

    my $attr_refs;

    my $file_resource_obj = $self->_file_resource_class->new(
        id => $params->{resource},
    );
    unless ($file_resource_obj->load( speculative => 1 )) {
        IC::Exception->throw("Can't load file resource obj: $params->{resource}");
    }
    my $file = $file_resource_obj->get_file_for_object( $object );
    unless (defined $file) {
        IC::Exception->throw( q{Can\'t find file-object } . $object->id . ' for resource ' . $file_resource_obj->id );
    }

    my $context         = {};
    my $form_values     = $context->{f}               = { resource => $params->{resource} };
    my $include_options = $context->{include_options} = {};

    if ($self->_step == 0) {
        $self->set_title("Unlink $_object_name File ($params->{resource})", $object);

        $context->{provided_form}    = 0;
        $context->{form_include}     = '_common_properties_unlink-' . $self->_step;
        $context->{_function}        = $self->_function;
        $context->{_step}            = $self->_step + 1;
        $context->{_properties_mode} = $params->{_properties_mode};
        $context->{form_referer}     = $ENV{HTTP_REFERER};

        for my $_pk_field (@_pk_fields) {
            $context->{pk_pairs}->{$_pk_field} = $params->{$_pk_field};
        }

        my $url_path = $file->url_path;
        if ($file->get_mimetype =~ /\Aimage/) {
            $include_options->{display_file} = qq{<img src="$url_path" />};
        }
        else {
            $include_options->{display_file} = qq{<a href="$url_path"><img src="} . $self->_icon_path . q{" /></a>};
        }

        $self->set_response(
            type    => 'component',
            kind    => 'form',
            context => $context,
        );
    }
    elsif ($self->_step == 1) {
        my $db = $object->db;
        eval {
            $db->begin_work;

            my $properties = $file->properties;
            for my $property (@$properties) {
                $property->delete;
            }
            $file->delete;
        };
        if ($@) {
            my $exception = $@;
            $db->rollback;
            die $exception;
        }
        $db->commit;

        $self->_referer_redirect_response;

        return;
    }
    else {
        IC::Exception->throw( 'Unrecognized step: ' . $self->_step);
    }

    return;
}

#
# TODO: add handling of file resources to drop files if the mixin is present
#
sub _common_drop {
    my $self = shift;
    
    my $_object_name = $self->_model_display_name;
    my $object       = $self->_common_implied_object;

    $self->set_title("Drop $_object_name", $object);

    if ($self->_step == 0) {
        my $context = {
            provided_form    => 0,
            form_include     => '_common_drop-' . $self->_step,
            form_referer     => $ENV{HTTP_REFERER},
            _function        => $self->_function,
            _step            => $self->_step + 1,
            f                => {
                object_desc      => $object->manage_description,
                object_type      => $_object_name,
            },
        };
        for my $pk_field (@{ $self->_model_class->meta->primary_key_columns }) {
            $context->{pk_pairs}->{'_pk_'.$pk_field} = $object->$pk_field();
        }

        if ($self->can('_drop_form_hook')) {
            $self->_drop_form_hook($object);
        }

        $self->set_response(
            type    => 'component',
            kind    => 'form',
            context => $context,
        );
    }
    elsif ($self->_step == 1) {
        if ($self->can('_drop_action_hook')) {
            $self->_drop_action_hook($object);
        }

        unless ($object->delete) {
            IC::Exception->( "Failed to delete object: " . $object->error );
        }

        $self->_referer_redirect_response;
    }
    else {
        IC::Exception->throw( 'Unrecognized step: ' . $self->_step );
    }

    return;
}

sub _common_detail_view {
    my $self = shift;

    my $_model_class = $self->_model_class;
    my $_object_name = $self->_model_display_name;
    my $_object_name_plural = $self->_model_display_name_plural;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };
    my @fields       = @{ $_model_class->meta->columns };

    my $object  = $self->_common_implied_object;
    my $context = {};

    $self->set_title("$_object_name Detail", $object);

    my $subtitle = '';
    
    my $list_link = $self->manage_function_link(
        method     => 'List',
        click_text => "[&nbsp;List&nbsp;$_object_name_plural&nbsp;]",
        role       => $self->_controller->role,
    );
    if (defined $list_link) {
        $subtitle .= $list_link;
    }
    $self->set_subtitle($subtitle);

    # TODO: test to see if we still need to do stringification
    
    my $pk_settings = [];
    for my $pk_field (@pk_fields) {
        push @$pk_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$pk_field", 
            value => $object->$pk_field,
        };
    }
    if (@$pk_settings) {
        $context->{pk_settings} = $pk_settings;
    }
     
    my @auto_fields = qw(date_created last_modified created_by modified_by);
    my $auto_settings = [];
    for my $field (@auto_fields) {
        my $value = $object->$field;
        if ($field =~ /_by$/ and $value =~ /^\d+$/) {
            my $value_obj = $self->_role_class->new( id => $value );
            if ($value_obj and $value_obj->load( speculative => 1)) {
                $value = $value_obj->display_label;
            }
        }
        push @$auto_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$field", 
            value => "$value",
        };
    }
    if (@$auto_settings) {
        $context->{auto_settings} = $auto_settings;
    }

    #
    # keep track of fields we link to as related objects,
    # then remove them from the "other" list
    #
    my @fo_fields;

    my $foreign_objects = [];
    unless ($self->_detail_suppress_foreign_objects) {
        for my $fk (@{ $self->_model_class->meta->foreign_keys }) {
            my $method      = $fk->name;
            my $foreign_obj = $object->$method;

            if (defined $foreign_obj) {
                my $fo_manage_class = $foreign_obj->manage_class;

                if (defined $fo_manage_class) {
                    push @fo_fields, keys %{ $fk->key_columns };

                    push @$foreign_objects, { 
                        #
                        # the following forces stringification
                        # which was necessary to prevent an issue
                        # where viewing the detail page caused 
                        # the user to get logged out
                        #
                        field => $fo_manage_class->_model_display_name,
                        value => $fo_manage_class->_object_manage_function_link(
                            'DetailView',
                            $foreign_obj,
                            label       => $foreign_obj->manage_description,
                            controller  => $self->_controller,
                            #link_format => '%s',
                        ) || $foreign_obj->manage_description,
                    };
                }
            }
        }
    }
    if (@$foreign_objects) {
        $context->{foreign_objects} = $foreign_objects;
    }

    my $other_setting_value_mappings = $self->_detail_other_mappings;

    my $other_settings = [];
    for my $field (sort @fields) {
        next if grep { $field eq $_ } @pk_fields, @auto_fields, @fo_fields;

        my $value = $object->$field || '';
        my $other_setting_ref = {
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$field",
        };
        push @$other_settings, $other_setting_ref;

        if (defined $other_setting_value_mappings->{$field}) {
            if (defined $other_setting_value_mappings->{$field}->{alternate_label}) {
                $other_setting_ref->{field} = $other_setting_value_mappings->{$field}->{alternate_label};
            }

            my $alt_object = $object;
            if (defined $other_setting_value_mappings->{$field}->{object_accessor}) {
                my $alt_object_method = $other_setting_value_mappings->{$field}->{object_accessor};
                $alt_object = $object->$alt_object_method;
            }

            if (defined $other_setting_value_mappings->{$field}->{value_accessor}) {
                my $sub_method = $other_setting_value_mappings->{$field}->{value_accessor};
                $other_setting_ref->{value} = $alt_object->$sub_method;
            }
            else {
                $other_setting_ref->{value} = $alt_object->manage_description;
            }
        }
        else {
            if ($field->type eq 'date') {
                $other_setting_ref->{value} = $object->$field( format => '%Y-%m-%d' );
            }
            else {
                $other_setting_ref->{value} = $object->$field;
            }
        }
    }
    if (@$other_settings) {
        $context->{other_settings} = $other_settings;
    }

    my $action_links = $context->{action_links} = [];

    if (defined $self->_parent_manage_class) {
        unless (defined $self->_parent_model_link_field) {
            IC::Exception->throw('_parent_manage_class defined without _parent_model_link_field set');
        }

        my $package = $self->_parent_manage_class;
        eval "use $package";
        if ($@) {
            warn "Can't load $package to generate parent link in common detail view\n";
        }
        else {
            my $method  = $self->_parent_model_link_field;

            push @$action_links, {
                html_link => $package->_object_manage_function_link(
                    'DetailView',
                    $object->$method,
                    label      => 'Go to Parent',
                    role       => $self->_controller->role,
                    controller => $self->_controller,
                ),
            };
        }
    }

    push @$action_links, { html_link => $self->_object_manage_function_link('Properties', $object, label => "Edit $_object_name") };
    push @$action_links, { html_link => $self->_object_manage_function_link('Drop', $object, label => "Drop $_object_name") };

    if ($self->can('_detail_generic_hook')) {
        my $content = { 
            left         => [],
            right        => [],
            bottom       => [],
            action_links => $action_links,
        };
        my $result = $self->_detail_generic_hook($object, $content);
        if ($result) {
            IC::Exception->throw("Hook returned error: $result");
        }
        $context->{hook_top_left_content}  = join '', @{$content->{left}};
        $context->{hook_top_right_content} = join '', @{$content->{right}};
        $context->{hook_bottom_content}    = join '', @{$content->{bottom}};
    }

    if (UNIVERSAL::can($object, 'get_file')) {
        my $has_privs = 0;

        my $function_obj = IC::M::ManageFunction->new( code => $self->_func_prefix . 'Properties' );
        if ($function_obj->load( speculative => 1 )) {
            if ($self->_controller->role->check_right( 'execute', $function_obj )) {
                $has_privs = 1;
            }
        }

        my $file_resource_refs = [];

        my $file_resource_objs = $object->get_file_resource_objs;
        for my $file_resource_obj (@$file_resource_objs) {
            my $file_resource_ref = {
                id      => $file_resource_obj->id,
                display => $file_resource_obj->lookup_value,
            };
            my @property_codes = map { $_->code } @{ $file_resource_obj->attrs };

            my $file = $file_resource_obj->get_file_for_object( $object );
            my $properties;
            if (defined $file) {
                $properties = $file->properties;

                if ($file->is_image) {
                    unless (grep { $_ eq 'width' } @property_codes) {
                        push @property_codes, 'width';
                    }
                    unless (grep { $_ eq 'height' } @property_codes) {
                        push @property_codes, 'height';
                    }
                }
            }

            my %property_values;
            if (defined $properties) {
                %property_values = $file->property_values( \@property_codes, as_hash => 1 );
            }

            my $attr_refs;
            for my $attr (@{ $file_resource_obj->attrs }) {
                my $attr_ref = {
                    code          => $attr->code,
                    display_label => $attr->display_label,
                };
                if (exists $property_values{$attr->code}) {
                    $attr_ref->{value} = $property_values{$attr->code};
                }

                push @$attr_refs, $attr_ref;
            }
            if (defined $file and $file->is_image) {
                $attr_refs ||= [];
                unless (grep { $_->{code} eq 'width' } @$attr_refs) {
                    push @$attr_refs, {
                        code          => 'width',
                        display_label => 'Auto: Width',
                        value         => $property_values{width},
                    };
                }
                unless (grep { $_->{code} eq 'height' } @$attr_refs) {
                    push @$attr_refs, {
                        code          => 'height',
                        display_label => 'Auto: Height',
                        value         => $property_values{height},
                    };
                }
            }
            if (defined $attr_refs) {
                $file_resource_ref->{attrs} = $attr_refs;
            }

            my $link_text;
            if (defined $file) {
                my $url_path = $file->url_path;
                if ($file->is_image) {
                    #
                    # images are just special
                    #
                    my ($use_width, $use_height, $use_alt) = $file->property_values( [ qw( width height alt ) ] );

                    $file_resource_ref->{url} = qq{<img src="$url_path" width="$use_width" height="$use_height"};
                    if (defined $use_alt) {
                        $file_resource_ref->{url} .= qq{ alt="$use_alt"};
                    }
                    $file_resource_ref->{url} .= ' />';
                }
                else {
                    $file_resource_ref->{url} = qq{<a href="$url_path"><img src="} . $self->_icon_path . q{" /></a>};
                }

                $link_text = 'Replace';

                if ($has_privs) {
                    $file_resource_ref->{drop_link} = $self->_object_manage_function_link(
                        'Properties',
                        $object,
                        label     => 'Drop',
                        addtl_cgi => {
                            _properties_mode => 'unlink',
                            resource         => $file_resource_ref->{id},
                        },
                    );
                }
            }
            else {
                $link_text = 'Upload';
            }

            if ($has_privs) {
                $file_resource_ref->{link} = $self->_object_manage_function_link(
                    'Properties',
                    $object,
                    label     => $link_text,
                    addtl_cgi => {
                        _properties_mode => 'upload',
                        resource         => $file_resource_ref->{id},
                    },
                );
            }

            push @$file_resource_refs, $file_resource_ref;
        }

        $context->{file_resources} = $file_resource_refs;
    }

    if (UNIVERSAL::can($object, 'log_actions')) {
        my $action_log = [];

        my $configuration = $self->_detail_action_log_configuration;

        for my $entry (@{ $object->action_log }) {
            my $entry_ref = {
                label        => $entry->action->display_label,
                by_name      => $entry->created_by_name,
                date_created => $entry->date_created,
                content      => ($entry->content || ''),
            };

            my @details;
            my @seen;

            #
            # TODO: add mapping for from/to actions
            #
            if (exists $configuration->{action_code_handlers}->{$entry->action_code}) {
                my $custom_sub = $configuration->{action_code_handlers}->{$entry->action_code};
                my ($details, $seen) = $custom_sub->($entry, $self->_controller->role);

                if (defined $details) {
                    push @details, @$details;
                }
                if (defined $seen) {
                    push @seen, @$seen;
                }
            }
            elsif (grep { $entry->action_code eq $_ } qw( status_change kind_change condition_change location_change )) {
                my ($from, $to) = ('', '');
                for my $detail (@{ $entry->details }) {
                    if ($detail->ref_code eq 'from') {
                        $from = $detail->value;
                        push @seen, $detail->ref_code;
                    }
                    elsif ($detail->ref_code eq 'to') {
                        $to = $detail->value;
                        push @seen, $detail->ref_code;
                    }
                }
                push @details, "from '$from' to '$to'" if (defined $from or defined $to);
            }
            for my $detail (@{ $entry->details }) {
                unless (grep { $detail->ref_code eq $_ } @seen) {
                    push @details, $detail->ref_code . ': ' . $detail->value;
                }
            }
            $entry_ref->{details} = join '<br />', @details;

            push @$action_log, $entry_ref;
        }

        if (@$action_log) {
            $context->{action_log} = $action_log;
        }
    }

    $self->set_response(
        type    => 'component',
        kind    => 'detail_view',
        context => $context,
    );

    return 1;
}

sub _common_detail_data_obj {
    my $self = shift;

    my $params = $self->_controller->parameters;
    $params->{_format} ||= 'json';

    my $_model_class = $self->_model_class;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };

    my $object  = $self->_common_implied_object;

    my $struct = {
        object_name => $self->_model_display_name,
        header_desc => $object->manage_description,
        tabs        => [],
    };

    # TODO: test to see if we still need to do stringification
    
    my $pk_settings = [];
    for my $pk_field (@pk_fields) {
        push @$pk_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$pk_field", 
            value => $object->$pk_field,
        };
    }
    $struct->{pk_settings} = $pk_settings;

    if ($self->_detail_use_default_summary_tab) {
        my $summary_tab = {
            label => 'Summary',
        };
        push @{ $struct->{tabs} }, $summary_tab;

        my @pk_fields = @{ $_model_class->meta->primary_key_columns };
        for my $pk_field (@pk_fields) {
            $summary_tab->{content}->{"$pk_field"} =  $object->$pk_field;
        }

        my $other_setting_value_mappings = $self->_detail_other_mappings;

        my @auto_fields = qw(date_created last_modified created_by modified_by);
        my @fields      = @{ $_model_class->meta->columns };
        for my $field (@fields) {
            next if grep { $field eq $_ } @pk_fields, @auto_fields;

            my $value = $object->$field || '';
            if (defined $other_setting_value_mappings->{$field}) {
                if (defined $other_setting_value_mappings->{$field}->{alternate_label}) {
                    $field = $other_setting_value_mappings->{$field}->{alternate_label};
                }

                my $alt_object = $object;
                if (defined $other_setting_value_mappings->{$field}->{object_accessor}) {
                    my $alt_object_method = $other_setting_value_mappings->{$field}->{object_accessor};
                    $alt_object = $object->$alt_object_method;
                }

                if (defined $other_setting_value_mappings->{$field}->{value_accessor}) {
                    my $sub_method = $other_setting_value_mappings->{$field}->{value_accessor};
                    $value = $alt_object->$sub_method;
                }
                else {
                    $value = $alt_object->manage_description;
                }
            }
            else {
                if ($field->type eq 'date') {
                    $value = $object->$field( format => '%Y-%m-%d' );
                }
                else {
                    $value = $object->$field;
                }
            }

            $summary_tab->{content}->{"$field"} = "$value";
        }
    }

    if (UNIVERSAL::can($object, 'get_file')) {
        my $files_tab = {
            label => 'Files',
        };
        push @{ $struct->{tabs} }, $files_tab;

        my $has_privs = 0;

        my $function_obj = IC::M::ManageFunction->new( code => $self->_func_prefix . 'Properties' );
        if ($function_obj->load( speculative => 1 )) {
            if ($self->_controller->role->check_right( 'execute', $function_obj )) {
                $has_privs = 1;
            }
        }

        my $file_resource_refs = $files_tab->{related} = [];

        my $file_resource_objs = $object->get_file_resource_objs;
        if (@$file_resource_objs) {
            my $count = 0;
            for my $file_resource_obj (@$file_resource_objs) {
                my $file_resource_ref = {
                    order   => $count,
                    label   => $file_resource_obj->lookup_value,
                    content => {
                        id => $file_resource_obj->id,
                    },
                };
                $count++;

                my @property_codes = map { $_->code } @{ $file_resource_obj->attrs };

                my $file = $file_resource_obj->get_file_for_object( $object );
                my $properties;
                if (defined $file) {
                    $properties = $file->properties;

                    if ($file->is_image) {
                        unless (grep { $_ eq 'width' } @property_codes) {
                            push @property_codes, 'width';
                        }
                        unless (grep { $_ eq 'height' } @property_codes) {
                            push @property_codes, 'height';
                        }
                    }
                }

                my %property_values;
                if (defined $properties) {
                    %property_values = $file->property_values( \@property_codes, as_hash => 1 );
                }

                my $attr_refs;
                for my $attr (@{ $file_resource_obj->attrs }) {
                    $attr_refs->{ $attr->display_label } = '';
                    if (exists $property_values{$attr->code} and defined $property_values{$attr->code}) {
                        $attr_refs->{ $attr->display_label } = $property_values{$attr->code};
                    }
                }
                if (defined $file and $file->is_image) {
                    $attr_refs ||= {};
                    unless (exists $attr_refs->{Width}) {
                        $attr_refs->{'Auto: Width'} = $property_values{width};
                    }
                    unless (exists $attr_refs->{Height}) {
                        $attr_refs->{'Auto: Height'} = $property_values{height};
                    }
                }
                if (defined $attr_refs) {
                    $file_resource_ref->{content}->{attrs} = $attr_refs;
                }

                my $link_text;
                if (defined $file) {
                    my $url_path = $file->url_path;
                    if ($file->is_image) {
                        #
                        # images are just special
                        #
                        my ($use_width, $use_height, $use_alt) = $file->property_values( [ qw( width height alt ) ] );

                        $file_resource_ref->{content}->{url} = qq{<img src="$url_path" width="$use_width" height="$use_height"};
                        if (defined $use_alt) {
                            $file_resource_ref->{content}->{url} .= qq{ alt="$use_alt"};
                        }
                        $file_resource_ref->{content}->{url} .= ' />';
                    }
                    else {
                        $file_resource_ref->{content}->{url} = qq{<a href="$url_path"><img src="} . $self->_icon_path . q{" /></a>};
                    }

                    $link_text = 'Replace';

                    if ($has_privs) {
                        $file_resource_ref->{content}->{drop_link} = $self->_object_manage_function_link(
                            'Properties',
                            $object,
                            label     => 'Drop',
                            addtl_cgi => {
                                _properties_mode => 'unlink',
                                resource         => $file_resource_ref->{id},
                            },
                        );
                    }
                }
                else {
                    $link_text = 'Upload';
                }

                if ($has_privs) {
                    $file_resource_ref->{content}->{link} = $self->_object_manage_function_link(
                        'Properties',
                        $object,
                        label     => $link_text,
                        addtl_cgi => {
                            _properties_mode => 'upload',
                            resource         => $file_resource_ref->{id},
                        },
                    );
                }

                push @$file_resource_refs, $file_resource_ref;
            }
        }
        else {
            $struct->{content} = 'No file resources configured.';
        }
    }

    if (UNIVERSAL::can($object, 'log_actions')) {
        my $log_tab = {
            label   => 'Log',
            content => 'This happens to be the log.',
        };
        push @{ $struct->{tabs} }, $log_tab;

        my $configuration = $self->_detail_action_log_configuration;

        my $action_log = [];

        for my $entry (@{ $object->action_log }) {
            my $date_created = $entry->date_created;

            my $entry_ref = {
                label        => $entry->action->display_label,
                by_name      => $entry->created_by_name,
                date_created => "$date_created",
                content      => ($entry->content || ''),
            };

            my $details = [];
            my $seen    = [];

            #
            # TODO: add mapping for from/to actions
            #
            if (exists $configuration->{action_code_handlers}->{$entry->action_code}) {
                my $custom_sub = $configuration->{action_code_handlers}->{$entry->action_code};
                my ($custom_details, $custom_seen) = $custom_sub->($entry, $self->_controller->role);

                if (defined $custom_details) {
                    push @$details, @$custom_details;
                }
                if (defined $custom_seen) {
                    push @$seen, @$custom_seen;
                }
            }
            elsif (grep { $entry->action_code eq $_ } qw( status_change kind_change condition_change location_change )) {
                my ($from, $to) = ('', '');
                for my $detail (@{ $entry->details }) {
                    if ($detail->ref_code eq 'from') {
                        $from = $detail->value;
                        push @$seen, $detail->ref_code;
                    }
                    elsif ($detail->ref_code eq 'to') {
                        $to = $detail->value;
                        push @$seen, $detail->ref_code;
                    }
                }
                push @$details, "from '$from' to '$to'" if (defined $from or defined $to);
            }
            for my $detail (@{ $entry->details }) {
                unless (grep { $detail->ref_code eq $_ } @$seen) {
                    push @$details, $detail->ref_code . ': ' . $detail->value;
                }
            }
            $entry_ref->{details} = $details;

            push @$action_log, $entry_ref;
        }

        if (@$action_log) {
            $log_tab->{action_log} = $action_log;
        }
    }

    if ($self->can('_detail_generic_hook_data_obj')) {
        my $result = $self->_detail_generic_hook_data_obj($object, $struct);
        if ($result) {
            IC::Exception->throw("Hook returned error: $result");
        }
    }

    # TODO: need to post process the tabs to set the indexes?
    #       can this be done on the client side?

    if ($params->{_format} eq 'json') {
        my $response = $self->_controller->response;
        $response->headers->status('200 OK');
        $response->headers->content_type('text/plain');
        #$response->headers->content_type('application/json');
        $response->buffer( JSON::Syck::Dump( $struct ));

        $self->_response(1);
    }
    else {
        IC::Exception->throw("Unrecognized _format: $params->{_format}");
    }

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
