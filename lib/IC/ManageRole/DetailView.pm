package IC::ManageRole::DetailView;

use Moose::Role;

requires '_ui_meta_struct';

with 'IC::ManageRole::Base';

has '+_prototype' => (
    default => 'Tabs',
);

has '_use_default_summary_tab' => (
    is      => 'ro',
    default => 1,
);
has '_action_log_configuration' => (
    is      => 'ro',
    default => sub { {} },
);

around 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::DetailView::ui_meta_struct";
    my $orig = shift;
    my $self = shift;

    my $params = $self->_controller->parameters;

    my $_model_class = $self->_model_class;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };
    my @fields       = @{ $_model_class->meta->columns };

    #
    # cache look up of field meta data objects by name of field for easy access
    #
    my $rdbo_fields_by_name = {
        map { $_->name => $_ } @fields
    };

    my $object = $self->_model_object;
    unless (defined $object) {
        $object = $self->object_from_pk_params($params);
        $self->_model_object($object);
    }

    my $struct = $self->_ui_meta_struct;
    $struct->{+__PACKAGE__} = 1;

    my $tabs = $struct->{_prototype_config}->{tabs} = [];

    if ($self->_use_default_summary_tab) {
        my $field_kv_defs = $self->_fields_to_kv_defs(
            fields => \@fields,
            object => $object,
        );

        my $edit_action = 'Properties';
        my $can_edit    = $self->check_priv($edit_action);
        my $field_form_defs;
        my $_pk_settings;
        if ($can_edit) {
            $field_form_defs = $self->_fields_to_field_form_defs(
                fields => \@fields,
                object => $object,
            );
            for my $pk_field (@pk_fields) {
                push @$_pk_settings, { 
                    field => '_pk_' . $pk_field->name, 
                    value => $object->$pk_field . '',
                };
            }
        }

        my $summary_tab = {
            label        => 'Summary',
            content_type => 'Grid',
        };
        push @$tabs, $summary_tab;

        my @pk_field_names   = map { $_->name } @pk_fields;
        my @auto_field_names = keys %{ { $_model_class->boilerplate_columns } };
        my @auto_fields      = map { $rdbo_fields_by_name->{$_} } @auto_field_names;

        #
        # TODO: handle foreign objects which may take up more than one field
        #       in the DB, but should always (?) be a select field and a single
        #       control and auto generate the pull down in the absence of more
        #       clear meta data
        #
        #       I suppose it would be possible to use multiple controls and 
        #       then use a value builder or similar to either load the object
        #       or construct a single value, etc. but handle the simple case first
        #

        my @other_fields;
        for my $field (@fields) {
            next if grep { $field->name eq $_ } (@pk_field_names, @auto_field_names);

            push @other_fields, $field;
        }

        #
        # TODO: add back in the ability to custom sort fields
        #

        my $content_to_build = [
            {
                row     => 0,
                col     => 0,
                percent => 50,
                type    => 'KeyValue',
                label   => 'Primary Key Fields and Values',
                # TODO: should these just be names?
                fields  => \@pk_fields,
            },
            {
                row     => 0,
                col     => 1,
                percent => 50,
                type    => 'KeyValue',
                label   => 'Auto Fields and Values',
                fields  => \@auto_fields,
            },
            {
                row     => 1,
                col     => 0,
                percent => 50,
                type    => 'KeyValue',
                label   => 'Other Fields and Values',
                fields  => \@other_fields,
            },
        ];

        for my $ref (@$content_to_build) {
            my $grid_ref = $summary_tab->{content}->[$ref->{row}]->[$ref->{col}] = {
                percent      => $ref->{percent},
                content_type => $ref->{type},
                content      => {
                    label   => $ref->{label},
                },
            };
            for my $field (@{ $ref->{fields} }) {
                my $data_ref = $field_kv_defs->{$field->name};
                if (defined $field_form_defs->{$field->name}) {
                    $data_ref->{form} = {
                        action         => $self->_controller->url(
                            controller => 'manage',
                            action     => 'run_action_method',
                            parameters => {
                                _class    => $self->_class,
                                _subclass => $edit_action,
                                _method   => 'save',
                            },
                            secure     => 1,
                        ),
                        pk             => $_pk_settings,
                        fields_present => [ $field->name ],
                        field_defs     => [
                            {
                                controls => [
                                    {
                                        name  => '_properties_mode',
                                        value => 'basic',
                                        type  => 'hidden',
                                    },
                                ],
                            },
                            $field_form_defs->{$field->name}
                        ],
                    };
                }
                push @{ $grid_ref->{content}->{data} }, $data_ref;
            }
        }
    }

    if (UNIVERSAL::can($object, 'get_file')) {
        my $files_tab = {
            label        => 'Files',
        };
        push @$tabs, $files_tab;

        #
        # TODO: switch to use check_priv
        #
        my $has_privs = 0;

        #my $function_obj = IC::M::ManageFunction->new( code => $self->_func_prefix . 'Properties' );
        #if ($function_obj->load( speculative => 1 )) {
            #if ($self->_controller->role->check_right( 'execute', $function_obj )) {
                #$has_privs = 1;
            #}
        #}

        #
        # TODO: file resources are designed to be adjacency lists so we really
        #       ought to be doing recursion here to build our tree structure
        #

        my $file_resource_objs = $object->get_file_resource_objs;
        if (@$file_resource_objs) {
            $files_tab->{content_type} = 'Tree';
            my $file_resource_refs = $files_tab->{content} = [];

            my $count = 0;
            for my $file_resource_obj (@$file_resource_objs) {
                my $file_resource_ref = {
                    order   => $count,
                    label   => $file_resource_obj->lookup_value,
                    content => {
                        data => {
                            id => $file_resource_obj->id,
                        },
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
                    $file_resource_ref->{content}->{data}->{attrs} = $attr_refs;
                }

                my $link_text;
                if (defined $file) {
                    my $url_path = $file->url_path;
                    if ($file->is_image) {
                        #
                        # images are just special
                        #
                        my ($use_width, $use_height, $use_alt) = $file->property_values( [ qw( width height alt ) ] );

                        $file_resource_ref->{content}->{data}->{url} = qq{<img src="$url_path" width="$use_width" height="$use_height"};
                        if (defined $use_alt) {
                            $file_resource_ref->{content}->{data}->{url} .= qq{ alt="$use_alt"};
                        }
                        $file_resource_ref->{content}->{data}->{url} .= ' />';
                    }
                    else {
                        $file_resource_ref->{content}->{data}->{url} = qq{<a href="$url_path"><img src="} . $self->_icon_path . q{" /></a>};
                    }

                    $link_text = 'Replace';

                    if ($has_privs) {
                        #$file_resource_ref->{content}->{data}->{drop_link} = $self->_object_manage_function_link(
                            #'Properties',
                            #$object,
                            #label     => 'Drop',
                            #addtl_cgi => {
                                #_properties_mode => 'unlink',
                                #resource         => $file_resource_ref->{id},
                            #},
                        #);
                    }
                }
                else {
                    $link_text = 'Upload';
                }

                if ($has_privs) {
                    #$file_resource_ref->{content}->{data}->{link} = $self->_object_manage_function_link(
                        #'Properties',
                        #$object,
                        #label     => $link_text,
                        #addtl_cgi => {
                            #_properties_mode => 'upload',
                            #resource         => $file_resource_ref->{id},
                        #},
                    #);
                }

                push @$file_resource_refs, $file_resource_ref;
            }
        }
        else {
            #$files_tab->{content_type} = 'Tree';
            $files_tab->{content}      = 'No file resources configured.';
        }
    }

    if (UNIVERSAL::can($object, 'log_actions')) {
        my $log_tab = {
            label        => 'Log',
            content_type => 'Table',
            content      => {
                caption => 'This happens to be the log.',
            },
        };
        push @$tabs, $log_tab;

        my $configuration = $self->_action_log_configuration;
        if (defined $configuration->{description}) {
            $log_tab->{content}->{description} = $configuration->{description};
        }

        $log_tab->{content}->{headers} = {
            action       => 'Action',
            performed_by => 'Performed By',
            performed_at => 'Performed At',
            details      => 'Details',
            content      => 'Content',
        };

        my $rows = $log_tab->{content}->{rows} = [];

        for my $entry (@{ $object->action_log }) {
            my $details = [];

            #
            # handle any customized details, marking those details as seen
            #
            my $seen = [];
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

            #
            # now loop through all details adding the ones that haven't been previously handled (seen)
            #
            for my $detail (@{ $entry->details }) {
                unless (grep { $detail->ref_code eq $_ } @$seen) {
                    push @$details, $detail->ref_code . ': ' . $detail->value;
                }
            }

            push @$rows, {
                action       => $entry->action->display_label,
                performed_by => $entry->created_by_name,
                performed_at => $entry->date_created . '',
                details      => $details,
                content      => ($entry->content || ''),
            };
        }
    }

    # TODO: need to post process the tabs to set the indexes?
    #       can this be done on the client side?

    return $self->$orig(@_);
};

no Moose;

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
