package IC::ManageRole::List;

use Moose::Role;

with 'IC::ManageRole::Base';

has '+_prototype' => (
    default => 'List',
);

has '_data_struct' => (
    is      => 'rw',
    default => sub { {} },
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

around 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::List::ui_meta_struct";
    my $orig = shift;
    my $self = shift;

    my $struct = $self->_ui_meta_struct;

    # TODO: add in filter meta config

    $struct->{+__PACKAGE__}    = 1;
    $struct->{label}           = 'List';
    $struct->{_prototype}      = 'List';
    $struct->{paging_provider} = $self->_paging_provider;
    $struct->{total_objects}   = $self->_model_class_mgr->get_objects_count;

    #
    # add this column to the data_table_column_defs but hide it,
    # so it will be available with the row record set but won't be
    # available in the to be shown columns
    #
    push @{ $struct->{data_table_column_defs} }, {
        key    => '_pk_settings',
        label  => 'PK Settings',
        hidden => 1,
    };
    push @{ $struct->{data_source_fields} }, {
        key    => '_pk_settings',
    };

    my $_cols = $self->_cols;
    for my $col (@$_cols) {
        push @{ $struct->{data_source_fields} }, {
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

        push @{ $struct->{$def_list_key} }, {
            key       => $col->{method},
            label     => $col->{display},

            # assume the best
            sortable  => (defined $col->{sortable} ? $col->{sortable} : 1),
            resizable => (defined $col->{resizable} ? $col->{resizable} : 1),

            (defined $col->{formatter} ? (formatter => $col->{formatter}) : ()),
            #class_opt => $col->{class_opt},
        };

        if (defined $col->{is_default_sort} and $col->{is_default_sort}) {
            $struct->{data_table_initial_sort} = {
                key => $col->{method},
                dir => $col->{default_sort_direction} || 'asc',
            };
        }
    }

    # TODO: this should be determined based off of column definitions
    $struct->{data_table_is_filterable} = 1;

    # TODO: restore ACL
    if (1) {
        #
        # ideally we could post process the row actions getting a meta data struct
        # for handling them, then just make a call to get the necessary data for 
        # the record to be used by the row actions, unfortunately that would require
        # even more refactoring so holding off on that now
        #
        push @{ $struct->{row_actions} }, {
            code  => 'DetailView',
            label => 'Detail',
        };
        push @{ $struct->{row_actions} }, {
            code  => 'Drop',
            label => 'Drop',
        };
    }

    return $self->$orig(@_);
};

sub data {
    #warn "IC::ManageRole::List::data";
    my $self = shift;
    my $args = { @_ };

    my $struct = $self->_data_struct;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;

    my $params = $self->_controller->parameters;

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

        $get_objects_config->{limit}  = $params->{results};
        $struct->{results}            = $get_objects_config->{limit};
        $struct->{sort}               = $sort_key;
        $struct->{dir}                = $add_desc ? 'desc' : 'asc';
    }

    ## TODO: this could be done on the client side via a formatter
    #my $prefix = $self->_func_prefix;
    #my $functions = [ 
        #{
            #code    => $prefix.'DetailView',
            #display => 'Detail',
        #},
    #];

    my @pk_fields = @{ $_model_class->meta->primary_key_columns };
    for my $object (@{ $_model_class_mgr->get_objects( %$get_objects_config ) }) {
        my $details = {};

        for my $pk_field (@pk_fields) {
            push @{ $details->{_pk_settings} }, { 
                field => '_pk_' . $pk_field->name, 
                value => $object->$pk_field . '',
            };
        }

        for my $col (@{ $self->_cols }) {
            my $method = $col->{method};

            my $value = $object->$method();
            $details->{ $method } = "$value";
        }

        #my $_options = '';
        #for my $func (@$functions) {
            ## TODO: add privilege check, etc.
            #my $object_pk = join '&', map { "_pk_$_=" . $object->$_ } @{ $object->meta->primary_key_columns };
            #my $link = qq|<a id="manage_menu_item-function-detail-$func->{code}-$object_pk" class="manage_function_link">$func->{display}</a> |;
            #$_options .= $link;
        #}
        #$details->{_options} = $_options;

        push @{ $struct->{rows} }, $details;
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
