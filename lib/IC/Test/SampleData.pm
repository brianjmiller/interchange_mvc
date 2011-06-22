package IC::Test::SampleData;

use Clone qw();
use Data::Dumper;

use Moose;
use MooseX::ClassAttribute;

class_has 'build_model' => (
    is      => 'ro',
    default => undef,
);
class_has 'build_config' => (
    is      => 'ro',
    default => undef,
);

no Moose;

#
# txn id is used in caching, we need to know specific transaction id
# to determine when a cache has "expired", or really just when we need
# to build a new set of data/objects/etc.
#
sub get_txn_id {
    my $self = shift;
    my $db   = shift;

    return $db->dbh->selectrow_array('SELECT txid_current()');
}

sub build_keys {
    my $self = shift;

    return [ keys %{ $self->build_config } ];
}

{
    my $dependencies = {};
    sub calculate_dependencies {
        my $self = shift;
        my $db   = shift;
        my $data = shift;

        if (ref $data eq 'HASH' and $data->{__dependency}) {
            die "'key' argument should be string not ref: $data->{key}\n" if ref $data->{key};

            my $txn_id = $self->get_txn_id($db);

            my $cache = $dependencies->{$txn_id}->{$data->{type}} ||= {};

            #warn "$self: checking dependency ($txn_id): " . Dumper($data) . "\n";
            my $object;
            if (defined $cache->{$data->{key}}) {
                $object = $cache->{$data->{key}}; 
                #warn "$self: dependency exists ($txn_id): $object - " . Dumper($data) . "\n";
            }
            else {
                (undef, $object) = $data->{type}->objects($db, key => [ $data->{key} ]);
                unless (defined $object) {
                    die "Unable to fetch dependency object: " . Dumper($data);
                }

                $cache->{$data->{key}} = $object;
                #warn "$self: fetched dependency ($txn_id): $object - " . Dumper($data) . "\n";
            }

            if (defined $data->{method}) {
                my $method = $data->{method};

                #warn "$self: running method on dependency $object ($method)";
                $data = $object->$method;
            }
            else {
                $data = $object;
            }
        }
        elsif (ref $data eq 'HASH') {
            while (my ($key, $val) = each %$data) {
                $data->{$key} = $self->calculate_dependencies($db, $val);
            }
        }
        elsif (ref $data eq 'ARRAY' and @$data) {
            for my $element (@$data) {
                $element = $self->calculate_dependencies($db, $element);
            }
        }

        return $data;
    }
}

{
    my $build_data_cache = {};
    sub build_data {
        my $self = shift;
        my $db   = shift;
        my %args = @_;

        unless ($db->begin_work == -1) {
            IC::Exception->throw('Cannot get build_data outside of a transaction (data corruption could be caused)');
        }

        my $request_keys = $args{key} || $self->build_keys;
        my $txn_id       = $self->get_txn_id($db);

        #warn "$self: build data request keys ($txn_id): " . Dumper($request_keys) . "\n";

        my $build_keys = [];
        for my $key (@$request_keys) {
            next if $build_data_cache->{$txn_id}->{ $self->build_model }->{$key};

            push @$build_keys, $key;
        }
        #warn "$self: build data build keys ($txn_id): " . Dumper($build_keys) . "\n";

        my $build_data = {};
        if (@$build_keys) {
            my $build_config = Clone::clone($self->build_config);

            #
            # get build config data for requested keys, then
            # get dependency objects that are needed, then 
            # create build data
            #
            for my $build_key (@$build_keys) {
                my $config_data = $build_config->{$build_key};
                unless (defined $config_data) {
                    IC::Exception->throw(sprintf 'Cannot get build_data: unrecognized build key (%s)', $build_key);
                }
                $config_data->{object_data} = $self->calculate_dependencies($db, $config_data->{object_data});

                $build_data->{$build_key} = $build_data_cache->{$txn_id}->{ $self->build_model}->{$build_key} = $config_data;
            }
        }

        return $build_data;
    }
}

{
    my $object_cache = {};
    sub objects {
        my $self = shift;
        my $db   = shift;
        my %args = @_;

        unless ($db->begin_work == -1) {
            IC::Exception->throw('Cannot get objects outside of a transaction (data corruption could be caused)');
        }

        #
        # determine which objects they are requesting, build list of keys
        #
        my $request_keys = $args{key} || $self->build_keys;
        #warn "$self: objects request_keys: " . Dumper($request_keys) . "\n";

        #
        # determine what transaction we are in and see which, if any, of the objects
        # that are being requested are cached for this transaction
        #
        my $txn_id = $self->get_txn_id($db);
        #warn "$self: objects txn_id: $txn_id\n";

        my $build_model = $self->build_model;

        my $cache = $object_cache->{$txn_id}->{$build_model} ||= {};

        my $build_keys = [];
        for my $key (@$request_keys) {
            next if $cache->{$key};

            push @$build_keys, $key;
        }
        #warn "$self: objects build_keys: " . Dumper($build_keys) . "\n";

        if (@$build_keys) {
            #
            # get build data for objects not yet cached, build them and then cache them,
            # part of doing that will be to determine the dependencies needed and load them
            # which will run the same cycle over
            #
            my $build_data  = $self->build_data($db, key => $build_keys);
            #warn "$self: objects build_data: " . Dumper($build_data) . "\n";

            while (my ($key, $ref) = each %$build_data) {
                #warn "$self: objects building object: " . $key . "\n";
                my $object = eval {
                    $cache->{$key} = $build_model->new(
                        db => $db,
                        %{ $ref->{object_data} },
                    )->save;

                    return $cache->{$key};
                };
                if ($@) {
                    local $Data::Dumper::Maxdepth = 3;
                    die "$self: Failed to build object: $key ($@) ($key)\n" . Dumper($ref);
                }
                #warn "$self: objects built object ($key): " . $object . "\n";

                if ($ref->{config}->{post_hooks}) {
                    #warn "$self: objects applying post hooks: " . $key . "\n";
                    for my $hook (@{ $ref->{config}->{post_hooks} }) {
                        if (defined $hook->{method}) {
                            my $method      = $hook->{method};
                            my @method_args = defined $hook->{method_args} ? @{ $self->calculate_dependencies($db, $hook->{method_args}) } : ();

                            eval {
                                $object->$method(@method_args);
                            };
                            if ($@) {
                                IC::Exception->throw("Cannot build object: $key - method post hook ($method) failed: $@");
                            }
                        }
                        elsif (defined $hook->{subroutine}) {
                            eval {
                                $hook->{subroutine}->($self, $object, $db);
                            };
                            if ($@) {
                                IC::Exception->throw("Cannot build object: $key - subroutine post hook failed: $@");
                            }
                        }
                        else {
                            IC::Exception->throw("Cannot build object: $key - cannot process post_hook (unrecognized configuration)");
                        }
                    }
                }
            }
        }

        my %return_objects;
        @return_objects{ @$request_keys } = @$cache{ @$request_keys };
        #warn "$self: return objects: " . Dumper(\%return_objects) . "\n";

        return wantarray ? %return_objects : \%return_objects;
    }
}

1;

__END__
