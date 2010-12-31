package IC::ManageRole::Add;

use Moose::Role;

with 'IC::ManageRole::Base';
with 'IC::ManageRole::ObjectSaver';

after 'ui_meta_struct' => sub {
    warn "IC::ManageRole::Add::ui_meta_struct(after)";
    my $self = shift;
    my %args = @_;

    warn "IC::ManageRole::Add::ui_meta_struct(after) - args keys: " . join(', ', keys %args);

    my $struct = $args{context}->{struct};

    $struct->{'IC::ManageRole::Add::ui_meta_struct(after)'} = 1;

    $struct->{label}        ||= 'Add';
    $struct->{renderer}     = {
        type   => 'FormWrapper',
        config => {},
    };

    my $form_def = $struct->{renderer}->{config}->{form_config} = {
        action         => $args{context}->{controller}->url(
            controller => 'manage',
            action     => 'run_action_method',
            parameters => {
                _class    => $self->_class,
                _subclass => 'Add',
                _method   => 'save',
            },
            secure     => 1,
        ),
        field_defs => [
            {   
                controls => [
                    {   
                        name  => '_properties_mode',
                        value => 'basic',
                        type  => 'HiddenField',
                    },
                ],
            },
        ],
    };

    my $_model_class = $self->_model_class;

    #
    # cache look up of field meta data objects by name of field for easy access
    #
    my $rdbo_fields_by_name = {
        map { $_->name => $_ } @{ $_model_class->meta->columns }
    };

    #
    # using all the columns in the object get the form defs,
    # this will leave out any fields not used in an add form
    #
    my $form_defs = $self->_fields_to_field_form_defs(
        fields => scalar $_model_class->meta->columns,
    );
    $form_def->{fields_present} = [ keys %$form_defs ];

    #
    # based on the fields present in the form defs get the
    # kv pairs so that we have access to the label
    #
    my $kv_defs = $self->_fields_to_kv_defs(
        fields => [ map { $rdbo_fields_by_name->{$_} } keys %$form_defs ],
    );

    while (my ($name, $ref) = each %$form_defs) {
        $ref->{label} = $kv_defs->{$name}->{label};

        push @{ $form_def->{field_defs} }, $ref;
    }

    #return $self->$orig(@_);
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
