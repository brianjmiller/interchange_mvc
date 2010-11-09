package IC::ManageRole::ObjectSaver;

use Moose::Role;

has '_response_struct' => (
    is      => 'rw',
    default => sub { {} },
);

sub save {
    warn "IC::ManageRole::ObjectSaver::save";
    my $self = shift;
    my $args = { @_ };

    my $params = $self->_controller->parameters;
    $params->{_format} ||= 'json';

    my $modified_by = $self->_controller->user->id;

    my $struct = $self->_response_struct;

    my $response_value = eval {
        #
        # TODO: include modified by and created by where necessary
        #
        if ($params->{_properties_mode} eq 'basic') {
            my $result;

            unless (defined $params->{fields_present} and @{ $params->{fields_present} }) {
                IC::Exception->throw('Missing required argument: fields_present[]');
            }

            my $_model_class    = $self->_model_class;
            my @fields          = $_model_class->meta->columns;
            my @pk_fields       = @{ $_model_class->meta->primary_key_columns };
            my @_pk_field_names = map { '_pk_' . $_->name } @pk_fields;

            #
            # cache look up of field meta data objects by name of field for easy access
            #
            my $rdbo_fields_by_name = {
                map { $_->name => $_ } @{ $_model_class->meta->columns }
            };

            #
            # get the structure used to override default behaviour for the fields,
            # it is keyed by DB field name
            #
            my $adjustments = $self->_field_adjustments || {};

            #
            # we distinguish an add from an edit by checking for the existence of
            # the _pk_* fields in the request, when they exist we should be able
            # to retrieve an object, this means that a checkbox or an unset radio
            # group couldn't be used for a PK...I think that is reasonable
            #
            my $is_edit = grep { defined $params->{$_} } @_pk_field_names;

            my $object = $self->_model_object;
            unless (defined $object) {
                if ($is_edit) {
                    $object = $self->object_from_pk_params($params);
                }
                else {
                    $object = $_model_class->new;
                }
                $self->_model_object($object);
            }

            my $field_form_defs = $self->_fields_to_field_form_defs(
                fields => [
                    map { $rdbo_fields_by_name->{$_} } @{ $params->{fields_present} }
                ],
            );

            #
            # while looping over the present fields it is possible through the value_builder
            # that a field would need to indirectly set the value of another field such that
            # they would be updated in tandem despite that field not actually being present,
            # so keep a list and process it after all present fields have been handled
            #
            my @non_present_updates;

            my %pk_fields_to_update;
            my %fields_present_by_name;
            my $alo_non_pk = 0;
            for my $field_name (@{ $params->{fields_present} }) {
                $fields_present_by_name{$field_name} = 1;

                #
                # ultimately we expect a single value for a given field to stuff
                # into the object (read: db column), unless the field is marked
                # as allowing nulls in which case this may be specifically used
                # to clear a value
                #
                my $value;

                #
                # we also want to provide back a list of controls that should be updated
                # so that the UI can (if it wishes) update a pre-existing form object to
                # reflect the newly submitted control values (in particular this matters
                # when a PK field is updated)
                #
                my $controls_to_update = [];

                my $adjustment = $adjustments->{$field_name} || {};

                my $allow_undef = 1;
                if (defined $adjustment->{allow_undef}) {
                    $allow_undef = $adjustment->{allow_undef};
                }
                else {
                    if ($rdbo_fields_by_name->{$field_name}->not_null) {
                        $allow_undef = 0;
                    }
                }

                #
                # see if there is an adjustment for determining the field value, if so,
                # call it and use that
                #
                if (defined $adjustment->{value_builder}) {
                    #
                    # TODO: should value_builder have to specify a list of controls that would
                    #       get passed values from the parameters?
                    #
                    my $additional_updates;
                    ($value, $additional_updates) = $adjustment->{value_builder}->{code}->($self, $object);

                    push @non_present_updates, @$additional_updates;
                }

                #
                # if there is more than one control we can't handle things automagically
                # as we have no way to determine which should be used to set the value
                # in the DB itself, and one of the adjustments listed above should have
                # provided us with a value if we are requiring one
                #
                if (not defined $value and @{ $field_form_defs->{ $field_name }->{controls} } == 1) {
                    #
                    # determine the control name used, check for definedness in the form
                    # which may be field type dependent
                    #
                    my $control = (@{ $field_form_defs->{ $field_name }->{controls} })[0];

                    $value = $params->{ $control->{name} };
                }

                if (defined $value and $rdbo_fields_by_name->{$field_name}->type eq 'boolean') {
                    if ($value eq 'true') {
                        $value = 1;
                    }
                    elsif ($value eq 'false') {
                        $value = 0;
                    }
                }

                #
                # if this is add, and the field is undefined then see if there is an
                # adjustment to handle that case, and call it to get the value
                #
                if (not defined $value and not $is_edit and defined $adjustment->{undef_on_add}) {
                    $value = $adjustment->{undef_on_add}->($self);
                }

                unless (defined $value or $allow_undef) {
                    IC::Exception->throw("Unable to determine value for not null field: $field_name");
                }

                #
                # run a validator check, presumably this is done client side first, but
                # we all know we can't trust the client to get things right
                #
                if (defined $adjustment->{server_validator}) {
                    if (ref $adjustment->{server_validator} eq 'CODE') {
                        $adjustment->{server_validator}->($value);
                    }
                    elsif ($adjustment->{server_validator} eq 'email') {
                        warn "Need to write the email validator";
                    }
                    else {
                        IC::Exception->throw("Unrecognized field validator: $adjustment->{has_validator}");
                    }
                }

                #
                # need to handle PKs differently in the case of edits, they need to be done
                # through an "update" statement because it is a known limitation in RDBO,
                # IOW a ->save can't update a PK field, but with adds the PK is required to
                # be set (at least one non-NULL field) when doing ->save
                #
                # technically I suppose we should be doing a check on the type of object
                # and whether it requires such handling since RDBO is only one possible
                # ORM in play, but we'll leave that for when we actually have a second since
                # there are other things in here that are likely RDBO specific
                #
                if ($is_edit and $rdbo_fields_by_name->{$field_name}->is_primary_key_member) {
                    $pk_fields_to_update{$field_name} = $value;
                    push @$controls_to_update, {
                        name  => '_pk_' . $field_name,
                        value => $value,
                    };
                }
                else {
                    $object->$field_name($value);
                    $alo_non_pk = 1;
                }

                $result->{fields}->{$field_name} = {
                    value              => $value,
                    controls_to_update => $controls_to_update,
                };
            }

            my %non_present_updates = ();
            for my $non_present (@non_present_updates) {
                my $field_name = $non_present->{db_field};
                if (exists $non_present_updates{$field_name}) {
                    IC::Exception->throw("Can't save object - non-present field collision: $field_name");
                }

                $object->$field_name($non_present->{value});

                $result->{fields}->{$field_name} = {
                    value    => $non_present->{value},
                    controls => [],
                };
            }

            #
            # for adds we want to check after the fact to see whether any additional fields
            # exist, aka that weren't considered present in the form and see if they have
            # default handler when undef
            #
            unless ($is_edit) {
                for my $field (@fields) {
                    my $field_name = $field->name;
                    next if exists $fields_present_by_name{$field_name};

                    if (defined $adjustments->{$field_name} and defined $adjustments->{$field_name}->{undef_on_add}) {
                        my $value = $adjustments->{$field_name}->{undef_on_add}->($self);
                        $object->$field_name($value);

                        $result->{fields}->{$field_name} = {
                            value    => $value,
                            controls => [],
                        };
                    }
                }
            }

            my $db = $object->db;
            $db->begin_work;

            eval {
                #
                # TODO: if we use individual hooks that can be set in each field
                #       can we remove the need for generic hooks, see 'undef_on_add'
                #       and/or example of server side validation on field basis
                #

                #
                # TODO: add back in pre update hook?
                #

                if ($alo_non_pk) {
                    $object->save;
                }

                if (keys %pk_fields_to_update) {
                    my $num_rows_updated = $self->_model_class_mgr->update_objects(
                        db    => $db,
                        set   => { %pk_fields_to_update },
                        where => [
                            map {
                                my $name = $_->name;
                                $name => $object->$name;
                            } @pk_fields,
                        ],
                    );
                    unless ($num_rows_updated > 0) {
                        IC::Exception->throw('Unable to update record based on PK values.');
                    }
                    if ($num_rows_updated > 1) {
                        IC::Exception->throw('Multiple rows updated when single primary key should match. SPEAK TO DEVELOPER!');
                    }

                    $object = $_model_class->new(
                        db => $db,
                        %pk_fields_to_update,
                    )->load;
                }

                #
                # TODO: add back in post update hook?
                #
            };
            my $e;
            if ($e = Exception::Class->caught) {
               eval { $db->rollback; };

               ref $e && $e->can('rethrow') ? $e->rethrow : die $e;
            }

            $db->commit;

            return $result;
        }
        elsif ($params->{_properties_mode} eq 'upload') {
            my $object = $self->_model_object;
            unless (defined $object) {
                $object = $self->object_from_pk_params($params);
                $self->_model_object($object);
            }

            unless (defined $params->{resource} and $params->{resource} ne '') {
                IC::Exception->throw('Required argument missing: resource');
            }

            my $file_resource_obj = $self->_file_resource_class->new(
                db => $object->db,
                id => $params->{resource},
            );
            unless ($file_resource_obj->load( speculative => 1 )) {
                IC::Exception->throw("Can't load file resource obj: $params->{resource}");
            }

            my $temporary_relative_path = File::Spec->catfile(
                'uncontrolled',
                '_manage_properties_upload',
                $object->meta->table,
                $object->serialize_pk,
                $file_resource_obj->sub_path( '_manage_properties_upload' ),
            );
            my $temporary_path = File::Spec->catfile(
                $self->_file_class->_htdocs_path,
                $temporary_relative_path,
            );

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

            umask 0002;

            File::Path::mkpath($temporary_path);

            open my $OUTFILE, ">$temporary_file" or die "Can't open file for writing: $!\n";
            binmode $OUTFILE;
            print $OUTFILE $file_contents;
            close $OUTFILE or die "Can't close written file: $!\n";

            my $file = $file_resource_obj->get_file_for_object( $object );
            if (defined $file) {
                $file->modified_by( $modified_by );
                $file->save;
            }
            else {
                $file_resource_obj->add_files(
                    {
                        db          => $object->db,
                        object_pk   => $object->serialize_pk,
                        created_by  => $modified_by,
                        modified_by => $modified_by,
                    },
                );
                $file_resource_obj->save;

                $file = $file_resource_obj->get_file_for_object( $object );
            }
            $file->store( $temporary_file, extension => $extension );

            # TODO: improve response to re-display file information
            return {
                message => 'File uploaded successfully.'
            };
        }
        elsif ($params->{_properties_mode} eq 'unlink') {
            my $object = $self->_model_object;
            unless (defined $object) {
                $object = $self->object_from_pk_params($params);
                $self->_model_object($object);
            }
        }
        else {
            IC::Exception->throw("Unrecognized _properties_mode: $params->{_properties_mode}");
        }
    };
    if ($@) {
        $struct->{code}      = 0;
        $struct->{exception} = "$@";
    }
    else {
        $struct->{code}  = 1;
        $struct->{value} = $response_value;
    }

    my $formatted = $struct;
    if (! defined $args->{format}) {
        return $formatted;
    }
    elsif ($args->{format} eq 'json') {
        return JSON::encode_json($formatted);
    }
    else {
        IC::Exception->throw("Unrecognized struct format: '$args->{format}'");
    }

    return;
}

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
