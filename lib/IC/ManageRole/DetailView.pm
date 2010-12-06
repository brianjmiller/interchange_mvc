package IC::ManageRole::DetailView;

use Image::Size;

use Moose::Role;

requires '_ui_meta_struct';

with 'IC::ManageRole::Base';

has '_use_default_summary_tab' => (
    is      => 'ro',
    default => 1,
);
has '_action_log_configuration' => (
    is      => 'ro',
    default => sub { {} },
);

my $edit_action = 'Properties';

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

    my $can_edit    = $self->check_priv($edit_action);

    my $_pk_settings;
    if ($can_edit) {
        for my $pk_field (@pk_fields) {
            push @$_pk_settings, { 
                field => '_pk_' . $pk_field->name, 
                value => $object->$pk_field . '',
            };
        }
    }

    my $struct = $self->_ui_meta_struct;
    $struct->{+__PACKAGE__} = 1;
    $struct->{type}         = 'Tabs';

    my $tabs = $struct->{config}->{data} = [];

    if ($self->_use_default_summary_tab) {
        my $field_kv_defs = $self->_fields_to_kv_defs(
            fields => \@fields,
            object => $object,
        );

        my $field_form_defs;
        if ($can_edit) {
            $field_form_defs = $self->_fields_to_field_form_defs(
                fields => \@fields,
                object => $object,
            );
        }

        my $summary_tab = {
            label        => 'Summary',
            content      => {
                type => 'Grid',
            },
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
            my $grid_ref = $summary_tab->{content}->{config}->[$ref->{row}]->[$ref->{col}] = {
                percent      => $ref->{percent},
                content      => {
                    type    => $ref->{type},
                    config  => {
                        label   => $ref->{label},
                    },
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
                                        type  => 'HiddenField',
                                        name  => '_properties_mode',
                                        value => 'basic',
                                    },
                                ],
                            },
                            $field_form_defs->{$field->name}
                        ],
                    };
                }
                push @{ $grid_ref->{content}->{config}->{data} }, $data_ref;
            }
        }
    }

    if (UNIVERSAL::can($object, 'get_file')) {
        my $files_tab = {
            label   => 'Files',
            content => {},
        };
        push @$tabs, $files_tab;

        my $file_resource_objs = $object->get_file_resource_objs;
        if (@$file_resource_objs) {
            $files_tab->{content}->{type}   = 'PanelLoader';
            $files_tab->{content}->{config} = {
                loader_config => {
                    type   => 'Tree',
                    config => {
                        data => [
                            {
                                id    => '_top',
                                label => 'Resources',
                            },
                        ],
                    },
                },
                panel_config  => {
                    data => {},
                },
            };

            my $file_resource_refs = $files_tab->{content}->{config}->{loader_config}->{config}->{data}->[0]->{branches} = [];
            my $panel_data         = $files_tab->{content}->{config}->{panel_config}->{data};

            for my $file_resource_obj (@$file_resource_objs) {
                my $config = $self->_file_resource_config(
                    $file_resource_obj,
                    $panel_data,
                    $object,
                    {
                        pk_settings => $_pk_settings,
                        can_edit    => $can_edit,
                    },
                );
                next unless defined $config;

                push @$file_resource_refs, $config;
            }
        }
        else {
            $files_tab->{content} = {
                type   => 'Basic',
                config => {
                    data => 'No file resources configured.',
                },
            };
        }
    }

    if (UNIVERSAL::can($object, 'log_actions')) {
        my $log_tab = {
            label   => 'Log',
            content => {
                type   => 'DataTable',
                config => {
                    caption => 'This happens to be the log.',
                },
            },
        };
        push @$tabs, $log_tab;

        my $configuration = $self->_action_log_configuration;
        if (defined $configuration->{description}) {
            $log_tab->{content}->{description} = $configuration->{description};
        }

        $log_tab->{content}->{config}->{headers} = {
            action       => 'Action',
            performed_by => 'Performed By',
            performed_at => 'Performed At',
            details      => 'Details',
            content      => 'Content',
        };

        my $rows = $log_tab->{content}->{config}->{rows} = [];

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

sub _file_resource_config {
    my $self = shift;
    my $node = shift;
    my $panel_data = shift;
    my $object = shift;
    my $args = shift;

    my $ref = {
        id        => $node->id,
        label     => $node->lookup_value,
        add_class => 'ic_renderer_panel_loader_control',
    };

    $panel_data->{ $node->id } = {
        content => {
            type   => 'Grid',
            config => [],
        },
    };

    my $grid_rows = $panel_data->{ $node->id }->{content}->{config};

    my $file = $node->get_file_for_object( $object );

    my @attribute_codes = map { $_->code } @{ $node->attrs };

    my $properties;
    if (defined $file) {
        $properties = $file->properties;

        if ($file->is_image) {
            unless (grep { $_ eq 'width' } @attribute_codes) {
                push @attribute_codes, 'width';
            }
            unless (grep { $_ eq 'height' } @attribute_codes) {
                push @attribute_codes, 'height';
            }
        }
    }

    my %attribute_values;
    if (defined $file) {
        %attribute_values = map {
            warn "file property: " . $_->id;
            $_->file_resource_attr->code => { id => $_->id, value => $_->value };
        } @{ $file->properties };
    }

    my $attr_refs = {};
    for my $attr (@{ $node->attrs }) {
        $attr_refs->{ $attr->code } = {
            _attr_id      => $attr->id,
            display_label => $attr->display_label,
            value         => $attribute_values{ $attr->code }->{value},
            id            => $attribute_values{ $attr->code }->{id},
        };
    }

    if (defined $file and $file->is_image) {
        if (! defined $attr_refs->{width}->{value} or ! defined $attr_refs->{height}->{value}) {
            my %auto;
            @auto{ qw( width height ) } = imgsize($file->local_path);

            for my $key (keys %auto) {
                unless (defined $attr_refs->{$key}->{value}) {
                    $attr_refs->{$key}->{display_only_value} = '(Auto: ' . $auto{$key} . ')';
                    $attr_refs->{$key}->{value}              = $auto{$key};
                }
            }
        }
    }

    if (defined $attr_refs) {
        my $attr_row = [
            {
                content => {
                    type   => 'KeyValue',
                    config => {
                        label => 'Attributes',
                        data  => [],
                    },
                },
            },
        ];
        push @$grid_rows, $attr_row;

        while (my ($code, $ref) = each %$attr_refs) {
            my $kv = {
                label => $ref->{display_label},
                value => (defined $ref->{display_only_value} ? $ref->{display_only_value} : $ref->{value}),
            };
            if (defined $file and defined $args->{can_edit} and $args->{can_edit}) {
                # TODO: restore ACL on file properties
                $kv->{form} = {
                    action         => $self->_controller->url(
                        controller => 'manage',
                        action     => 'run_action_method',
                        parameters => {
                            _class    => 'Files__Properties',
                            _subclass => (defined $ref->{id} ? 'Properties' : 'Add'),
                            _method   => 'save',
                        },
                        secure     => 1,
                    ),
                    fields_present => [ 'value' ],
                    field_defs     => [
                        {
                            controls => [
                                {   
                                    type  => 'HiddenField',
                                    name  => '_properties_mode',
                                    value => 'basic',
                                },
                            ],
                        },
                        {
                            controls => [
                                {
                                    name  => 'value',
                                    value => $ref->{value},
                                },
                            ],
                        }
                    ],
                };
                if (defined $ref->{id}) {
                    $kv->{form}->{pk} = [
                        {
                            field => '_pk_id',
                            value => "$ref->{id}",
                        },
                    ];
                }
                else {
                    push @{ $kv->{form}->{fields_present} }, qw( file_id file_resource_attr_id );
                    push @{ $kv->{form}->{field_defs}->[0]->{controls} }, (
                        {
                            type  => 'HiddenField',
                            name  => 'file_resource_attr_id',
                            value => "$ref->{_attr_id}",
                        },
                        {
                            type  => 'HiddenField',
                            name  => 'file_id',
                            value => $file->id . '',
                        },
                    );
                }
            }

            push @{ $attr_row->[0]->{content}->{config}->{data} }, $kv;
        }
    }

    if (defined $args->{can_edit} and $args->{can_edit}) {
        my $form_row = [
            {
                content => {
                    type   => 'FormWrapper',
                    config => {
                        caption     => 'File handling',
                        form_config => {
                            # TODO: improve the handling of this on the client side
                            encodingType   => 2,

                            action         => $self->_controller->url(
                                controller => 'manage',
                                action     => 'run_action_method',
                                secure     => 1,
                                parameters => {
                                    _class    => $self->_class,
                                    _subclass => $edit_action,
                                    _method   => 'save',
                                },
                            ),
                            pk             => $args->{pk_settings},
                            fields_present => [ 'uploaded_file' ],
                            field_defs     => [
                                {
                                    controls => [
                                        {
                                            type  => 'HiddenField',
                                            name  => '_properties_mode',
                                            value => 'upload',
                                        },
                                        {
                                            type  => 'HiddenField',
                                            name  => 'resource',
                                            value => $node->id . '',
                                        },
                                        {
                                            label => 'File to Upload',
                                            name  => 'uploaded_file',
                                            type  => 'FileField',
                                        },
                                    ],
                                },
                            ],
                            buttons => [
                                {
                                    name  => 'submit',
                                    value => (defined $file ? 'Replace' : 'Upload'),
                                    type  => 'SubmitButton',
                                },
                            ],
                        },
                    },
                },
            }
        ];
        push @$grid_rows, $form_row;
    }

    my $display_row = [
        {
            content => {
                type   => 'Basic',
                config => {
                    label => 'File',
                    data  => 'No file uploaded yet.',
                },
            },
        },
    ];
    push @$grid_rows, $display_row;

    if (defined $file) {
        my $content;

        my $url_path = $file->url_path;
        if ($file->is_image) {
            #
            # images are just special
            #
            my ($use_width, $use_height, $use_alt) = $file->property_values( [ qw( width height alt ) ] );

            $content = qq{<img src="$url_path" width="$use_width" height="$use_height"};
            if (defined $use_alt) {
                $content .= qq{ alt="$use_alt"};
            }
            $content .= ' />';
        }
        else {
            $content = qq{<a href="$url_path"><img src="} . $self->_icon_path . q{" /></a>};
        }

        $display_row->[0]->{content}->{config}->{data} = $content;

        if (defined $args->{can_edit} and $args->{can_edit}) {
            # TODO: restore ability to unlink file
        }
    }

    for my $child (@{ $node->children }) {
        my $config = $self->_file_resource_config($child, $panel_data, $object, %$args);
        next unless defined $config;

        push @{ $ref->{branches} }, $config;
    }

    return $ref;
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
