package IC::ManageRole::List;

use Moose::Role;

with 'IC::ManageRole::Base';

has '_data_struct' => (
    is      => 'rw',
    default => sub { {} },
);
has '_subclass' => (
    is      => 'rw',
    default => 'List',
);
has '_data_method' => (
    is      => 'rw',
    default => 'data',
);

has '_cols' => (
    is      => 'ro', 
    default => sub {
        [
            { 
                display  => 'Description',
                method   => 'manage_description',
                parser   => 'string',
                sortable => 0,
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

has '_paging_provider' => (
    is      => 'ro',
    default => 'client',
);

after 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::List::ui_meta_struct(after)";
    my $self = shift;
    my %args = @_;

    my $struct = $args{context}->{struct};

    $struct->{'IC::ManageRole::List::ui_meta_struct(after)'} = 1;

    $struct->{label}              ||= 'List';
    $struct->{renderer}->{type}   ||= 'RecordSet';
    $struct->{renderer}->{config} ||= {};

    my $config = $struct->{renderer}->{config}->{data_table} = {
        data_url => $args{context}->{controller}->url(
            controller => 'manage',
            action     => 'run_action_method',
            parameters => {
                _class    => $self->_class,
                _subclass => $self->_subclass,
                _method   => $self->_data_method,
            },
            get => {
                # TODO: need to pass _format through from parameters
                _format => 'json',
            },
            secure     => 1,
        ),
    };

    $config->{paging_provider} = $self->_paging_provider;
    $config->{total_objects}   = $self->_model_class_mgr->get_objects_count;

    #
    # add this column to the data_table_column_defs but hide it,
    # so it will be available with the row record set but won't be
    # available in the to be shown columns
    #
    push @{ $config->{data_table_column_defs} }, {
        key    => '_record_config',
        label  => 'Record Config',
        hidden => 1,
    };
    push @{ $config->{data_source_fields} }, {
        key    => '_record_config',
    };

    my $_cols = $self->_cols;
    for my $col (@$_cols) {
        push @{ $config->{data_source_fields} }, {
            key    => $col->{method},
            parser => $col->{parser},
        };

        #
        # initially hidden column defs are separated out so that we can provide
        # a control on the table to allow them to be added later
        #
        my $def_list_key = 'data_table_column_defs';
        if (defined $col->{is_initially_hidden} and $col->{is_initially_hidden}) {
            $def_list_key = 'data_table_hidden_column_defs';
        }

        push @{ $config->{$def_list_key} }, {
            key       => $col->{method},
            label     => $col->{display},

            sortable  => (defined $col->{sortable} ? $col->{sortable} : 1)
                ? JSON::true() : JSON::false(),
            resizeable => (defined $col->{resizable} ? $col->{resizable} : 1)
                ? JSON::true() : JSON::false(),

            (defined $col->{formatter} ? (formatter => $col->{formatter}) : ()),
        };

        if (defined $col->{is_default_sort} and $col->{is_default_sort}) {
            $config->{data_table_initial_sort} = {
                key => $col->{method},
                dir => $col->{default_sort_direction} || 'asc',
            };
        }
    }

    # TODO: this should be determined based off of column definitions
    $config->{data_table_is_filterable} = JSON::true();

    # TODO: provide a way to deactivate the options handling
    $config->{data_table_include_options} = JSON::true();

    return;
};

sub data {
    #warn "IC::ManageRole::List::data";
    my $self = shift;
    my %args = @_;

    my $struct = $args{context}->{struct};
    my $params = $args{context}->{controller}->parameters;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;


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
        for my $col (@{ $self->_cols }) {
            next unless $col->{method} eq $params->{sort};

            $found_sort_col = $col;
            last;
        }
        unless (defined $found_sort_col) {
            warn "Attempt to sort on '$params->{sort}' but found no matching column (" . $self->_class . ")";
        }
        if (defined $params->{dir} and $params->{dir} eq 'desc') {
            $add_desc = 1;
        }
    }
    else {
        # no sort passed, check our list of columns for the default to use
        for my $col (@{ $self->_cols }) {
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

    if ($self->_paging_provider eq 'server') {
        $get_objects_config->{offset} = $params->{startIndex} || 0;
        $struct->{startIndex}         = $get_objects_config->{offset};

        $get_objects_config->{limit}  = $params->{results} || 25;
        $struct->{results}            = $get_objects_config->{limit};
        $struct->{sort}               = $sort_key;
        $struct->{dir}                = $add_desc ? 'desc' : 'asc';
    }

    my $class_model_obj = $self->get_class_model_obj;

    # TODO: restore access control check
    my $action_models = $class_model_obj->find_actions(
        query => [
            is_primary => 0,
        ],
    );
    my %action_labels_by_code = (
        map { $_->code => $_->display_label } @$action_models,
    );

    for my $object (@{ $_model_class_mgr->get_objects( %$get_objects_config ) }) {
        my $details = {
            _record_config => {
                unique   => $object->as_hashkey . '',
                label    => $object->manage_description . '',
                meta_url => $args{context}->{controller}->url(
                    controller => 'manage',
                    action     => 'run_action_method',
                    parameters => {
                        _class    => $self->_class,
                        _method   => 'object_ui_meta_struct',
                    },
                    get => {
                        _format => 'json',
                        map {
                            '_pk_' . $_->name => $object->$_ . ''
                        } @{ $_model_class->meta->primary_key_columns }
                    },
                    secure     => 1,
                ),
            },
        };

        for my $col (@{ $self->_cols }) {
            my $method = $col->{method};

            my $value = $object->$method();
            $details->{ $method } = "$value";
        }

        my $_options = $details->{_options} = [];
        for my $action ($self->_record_actions($object)) {
            push @$_options, {
                code  => $action,
                label => $action_labels_by_code{$action},
            };
        }

        push @{ $struct->{rows} }, $details;
    }

    return;
};

no Moose;

{
    #
    # each element of the search by value contains a single
    # query element specification as,
    #
    #   field = [delimiter-]operator[-operator]*
    #
    # where field matches a field in the model class being
    # queried, and the operator(s) match a query operator
    # the model class field understands
    #
    # multiple values may be provided, separated by "delimiter"
    # where the delimiter is any non-dash, non-operator name
    # (defaults to comma) passed as the first segment after
    # the equals sign
    #
    my $_simple_sub = sub {
        return $_[0];
    };
    my $_percent_wrapper_sub = sub {
        return '%' . $_[0] . '%';
    };
    my $_search_by_operators = {
        eq    => $_simple_sub,
        ne    => $_simple_sub,
        lt    => $_simple_sub,
        gt    => $_simple_sub,
        le    => $_simple_sub,
        ge    => $_simple_sub,
        ilike => $_percent_wrapper_sub,
        like  => $_percent_wrapper_sub,
    };

    sub _process_search_by {
        my $self = shift;
        my $params = shift;

        my @return;

        for my $search_by (@{ $params->{search_by} }) {
            if ($search_by =~ /\A(.*)=(.*)\z/) {
                my $field    = $1;
                my $operator = $2;

                if ($operator =~ /-/) {
                    my @operators = split /-/, $operator;
                    my $delimiter = ',';
                    unless (exists $_search_by_operators->{$operators[0]}) {
                        $delimiter = shift @operators;
                    }

                    my @values = split /$delimiter/, $params->{$field};
                    unless (@values == @operators) {
                        IC::Exception->throw('_process_search_by failed: # of operators does not match # of values');
                    }

                    for my $index (0..@operators - 1) {
                        my $operator_sub = $_search_by_operators->{ $operators[$index] };
                        unless (defined $operator_sub) {
                            IC::Exception::FeatureNotImplemented->throw( "_process_search_by failed: unrecognized operator '$operators[$index]'" );
                        }

                        push @return, (
                            $field => {
                                $operators[$index] => $operator_sub->($values[$index]),
                            },
                        );
                    }
                }
                else {
                    unless (exists $_search_by_operators->{$operator}) {
                        IC::Exception::FeatureNotImplemented->throw( "_process_search_by failed: unrecognized operator '$operator'" );
                    }

                    push @return, ( 
                        $field => {
                            $operator => $_search_by_operators->{$operator}->($params->{$field}),
                        },
                    );
                }
            }
        }

        return @return;
    }
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
