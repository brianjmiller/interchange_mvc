package IC::ManageRole::Drop;

use Moose::Role;

requires '_ui_meta_struct';

with 'IC::ManageRole::Base';

has '+_prototype' => (
    default => 'Form',
);

has '_response_struct' => (
    is      => 'rw',
    default => sub { {} },
);

around 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::Drop::ui_meta_struct";
    my $orig = shift;
    my $self = shift;

    my $params = $self->_controller->parameters;

    my $object = $self->_model_object;
    unless (defined $object) {
        $object = $self->object_from_pk_params($params);
        $self->_model_object($object);
    }

    my $_model_class = $self->_model_class;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };

    my $_pk_settings;
    for my $pk_field (@pk_fields) {
        push @$_pk_settings, { 
            field => '_pk_' . $pk_field->name, 
            value => $object->$pk_field . '',
        };
    }

    my $struct = $self->_ui_meta_struct;
    $struct->{+__PACKAGE__}      = 1;

    $struct->{_prototype_config} = {
        caption     => 'Are you sure you wish to delete the following ' . $self->_model_display_name . ': <span class="emphasized">' . $object->manage_description . '</span>',
        form_config => {
            pk     => $_pk_settings,
            action => $self->_controller->url(
                controller => 'manage',
                action     => 'run_action_method',
                parameters => {
                    _class    => $self->_class,
                    _subclass => 'Drop',
                    _method   => 'save',
                },
                secure     => 1,
            ),
        },
    };

    return $self->$orig(@_);
};

sub save {
    warn "IC::ManageRole::Drop::save";
    my $self = shift;
    my $args = { @_ };

    my $params = $self->_controller->parameters;
    $params->{_format} ||= 'json';

    my $struct = $self->_response_struct;

    my $response_value = eval {
        my $result;

        my $object = $self->_model_object;
        unless (defined $object) {
            $object = $self->object_from_pk_params($params);
            $self->_model_object($object);
        }

        my $db = $object->db;
        $db->begin_work;

        eval {
            #
            # TODO: add back in pre drop hook?
            #

            $object->delete;

            #
            # TODO: add back in post drop hook?
            #
        };
        my $e;
        if ($e = Exception::Class->caught) {
           eval { $db->rollback; };

           ref $e && $e->can('rethrow') ? $e->rethrow : die $e;
        }

        $db->commit;

        return $result;
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
