package IC::ManageRole::ObjectAdjuster::Simple;

use Moose::Role;

# must be overridden by the subclass
has '_object_adjust_simple_subclass' => (
    is => 'rw',
);
has '_object_adjust_simple_label' => (
    is      => 'rw',
    default => 'Simple',
);

has '_save_method' => (
    is      => 'rw',
    default => 'save',
);

after 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::ObjectAdjuster::Simple::ui_meta_struct(after)";
    my $self = shift;
    my %args = @_;

    my $params = $args{context}->{controller}->parameters;
    my $object = $args{context}->{object};
    my $struct = $args{context}->{struct};

    my $_model_class = $self->_model_class;

    $struct->{'IC::ManageRole::ObjectAdjuster::Simple::ui_meta_struct(after)'} = 1;

    $struct->{label} ||= $self->_object_adjust_simple_label;

    # TODO: is this still needed after the context restructure?
    # provide a hook into the subclass to let it override what it needs to
    $self->_simple_object_adjust_ui_meta_struct($struct, $object);

    unless (defined $struct->{type}) {
        $struct->{type} = 'FormWrapper';
    }

    if ($struct->{type} eq 'FormWrapper') {
        unless (defined $struct->{config}->{form_config}->{pk}) {
            my @pk_fields    = @{ $_model_class->meta->primary_key_columns };

            my $_pk_settings;
            for my $pk_field (@pk_fields) {
                push @$_pk_settings, { 
                    field => '_pk_' . $pk_field->name, 
                    value => $object->$pk_field . '',
                };
            }
            $struct->{config}->{form_config}->{pk} = $_pk_settings;
        }
        unless (defined $struct->{config}->{form_config}->{action}) {
            $struct->{config}->{form_config}->{action} = $args{context}->{controller}->url(
                controller => 'manage',
                action     => 'run_action_method',
                parameters => {
                    _class    => $self->_class,
                    _subclass => $self->_object_adjust_simple_subclass,
                    _method   => ($self->_save_method || 'save'),
                },
                secure     => 1,
            );
        }
    }

    return;
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
