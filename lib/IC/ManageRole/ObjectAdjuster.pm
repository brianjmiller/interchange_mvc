package IC::ManageRole::ObjectAdjuster;

use Moose::Role;

has '_response_struct' => (
    is      => 'rw',
    default => sub { {} },
);

sub save {
    warn "IC::ManageRole::ObjectAdjuster::save";
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
            $result = $self->_save_object_adjust($object, $params);
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

sub _save_object_adjust {
    IC::Exception->throw('_save_object_adjust should be overridden by subclass');
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
