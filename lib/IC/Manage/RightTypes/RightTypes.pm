sub _properties_action_hook {
    my $self = shift;

    my $params = $self->_controller->parameters;

    # special case of empty string to NULL
    if ($params->{target_kind_code} eq '') {
        $params->{target_kind_code} = undef;
    }

    return;
}

