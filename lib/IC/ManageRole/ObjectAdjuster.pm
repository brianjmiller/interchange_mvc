package IC::ManageRole::ObjectAdjuster;

use Moose::Role;

sub save {
    #warn "IC::ManageRole::ObjectAdjuster::save";
    my $self = shift;
    my %args = @_;

    my $params = $args{context}->{controller}->parameters;
    my $struct = $args{context}->{struct};

    my $response_value = eval {
        my $result;

        my $object = $self->object_from_params($params);

        my $db = $object->db;
        $db->begin_work;

        my $modified_by = $args{context}->{controller}->role->id;

        eval {
            $result = $self->_save_object_adjust(
                $object,
                $params,
                 modified_by => $modified_by,
             );
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

    return;
}

#
# Moose Role rules state we can't provide the following method or there will be
# a collision if another role (such as Drop) provides the method as well
#
#sub _save_object_adjust {
    #IC::Exception->throw('_save_object_adjust should be overridden by subclass');
#}

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
