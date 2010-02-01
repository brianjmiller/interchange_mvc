package IC::Model::Rose::Object;

use strict;
use warnings;

use Rose::DB::Object;
use base qw(Rose::DB::Object IC::Model);

# Make a _logger attribute with get_logger/set_logger accessors,
# which will fit nicely into the IC::Log::Logger paradigm inherited
# from IC::Model.

# use Rose tool for generating a "_logger" attribute.
use Rose::Object::MakeMethods::Generic (
    'scalar --get_set' => '_logger',
);

# wrap _logger attribute with more explicitly-named methods
sub get_logger {
    my $self = shift;
    return $self->_logger;
}

sub set_logger {
    my ($self, @args) = @_;
    @args = (undef) unless @args;
    return $self->_logger(@args);
}

my $determine_manager_package = sub {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    return "${class}::Manager";
};

# magical method for creating the manager package magically
# when called by a subclass.
sub make_manager_package {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    my $target_package = $invocant->$determine_manager_package();
    my $isa_name = $target_package . '::ISA';

    my $model_class_subname = "${target_package}::object_class";
    my $model_class_sub = sub { return $class };
    {
        no strict 'refs';
        @$isa_name = qw( IC::Model::Rose::Object::Manager );
        *$model_class_subname = $model_class_sub;
    }
    
    $target_package->make_manager_methods( 'instances' );
}

# implement the IC::Model interface...
# The model class must have done the make_manager_package() call,
# or followed its lead in implementing its own manager package.
my %delegations = qw(
    _find           get_instances
    _count          get_instances_count
    _find_by_sql    get_objects_from_sql
    _set            update_instances
    _remove         delete_instances
);
for my $method (keys %delegations) {
    my $target = $delegations{$method};

    my $subref = sub {
        my $self = shift;
        my $package = $self->$determine_manager_package();
        my $sub = $package->can($target);

        return $package->$sub( @_ );
    };

    no strict 'refs';
    *$method = $subref;
}

# Lexical block enclosing looping structure transform data.
{
	my $loops;
	my $loop_data;
	my $loop_meta;
	my $loop_counters;

	my $reset_loop = sub {
		my ($self, $loop_name, $relations) = @_;
		if (my $old_data = $loops->{$loop_name}) {
			delete @$loop_data{@$old_data};
		}
		$loops->{$loop_name} = [];
		return;
	};

	my $resolve_associations = sub {
		my ($self, $relations) = @_;
		my (%structures, @start, %struct_seen, %start_seen, %assoc_lists, %processing);
		my $result = {
            associations => \%structures,
            base         => \@start,
            processing   => \%processing,
        };
		return $result unless $relations and @$relations;

		%assoc_lists = map { $_ => [ split /\.+/, $_ ] } @$relations;
		for my $assoc (sort { scalar(@{$assoc_lists{$b}}) <=> scalar(@{$assoc_lists{$a}}) } @$relations) {
			my $list = $assoc_lists{$assoc};
			while (scalar(@$list) > 1) {
				my $outer = pop @$list;
				my $base_assoc = join '.', @$list;
				next if $struct_seen{$base_assoc . '.' . $outer};
				push @{$structures{$base_assoc} ||= []}, $outer;
			}
			# Now only 1 item left; put it on the base stack (the starting point for row transformation)
			push @start, $list->[0] if ! $start_seen{$list->[0]}++;
		}
		
		return $result;
	};

	my $itl_loop;

	my $resolve_structure = sub {
		my ($self, $loop_name, $assoc_name, $relations, $assoc_map) = @_;
		my $name = $loop_name;
		$name .= ':' . $assoc_name if $assoc_name;
		my $meta;
		# print STDERR "Into structure resolution for name '$name' association '$assoc_name'\n";
		if (! ($meta = ${$loop_meta->{$loop_name} ||= {}}{$assoc_name})) {
			my (%seen, @columns, @functions, @relnames, @relfunctions);
			@columns
				= grep {! $seen{$_}++}
				(
					$self->meta->primary_key_column_names,
					$self->meta->column_names,
				)
			;
			@functions = map { $self->meta->column_accessor_method_name( $_ ) } @columns;
			@relnames = @$relations if $relations and @$relations;
			@relfunctions
				= map {
					my $rel = $_;
					$self->meta->relationship($rel) || $self->meta->foreign_key($rel)
						or die "Invalid relationship '$_' specified!";
					my $new_assoc = $assoc_name ? "$assoc_name.$rel" : $_;
					my $new_name = $loop_name . ':' . $new_assoc;
					#print STDERR "Adding relationship function for relation '$rel' new name '$new_name' new assoc '$new_assoc'\n";
					sub {
						my $obj = shift;
						my (@list);
						$new_name .= ':' . $loop_counters->{$new_assoc}++;
						# print STDERR "fetching relationship data for relationship '$rel' name '$new_name' assoc '$new_assoc'\n";
						{
							no strict 'refs';
							@list = ($obj->$rel());
						}
						for my $item (@list) {
							$item->$itl_loop($new_name, $new_assoc, undef, $assoc_map,);
						}
						@list ? $new_name : undef;
					};
				}
				@relnames
			;
			$meta->{names} = [ @columns, @relnames, ];
			$meta->{functions} = [ @functions, @relfunctions, ];
			$loop_meta->{$loop_name}->{$assoc_name} = $meta;
		}
		return $meta;
	};

	$itl_loop = sub {
		my ($self, $loop_name, $assoc_name, $base, $assoc_map, ) = @_;
		my $my_name = $loop_name;
		my ($meta);
		if (! $assoc_name) {
			$meta = $self->$resolve_structure($loop_name, $assoc_name, $base, $assoc_map,);
		}
		else {
			$meta = $self->$resolve_structure($loop_name, $assoc_name, $assoc_map->{$assoc_name}, $assoc_map,);
		}
		# print STDERR "itl_loop: name '$my_name', assoc '$assoc_name', meta:\n" . Dumper($meta) . "\n";
		my $target = $loop_data->{$my_name} ||= [];
		if (! @$target) {
			my $i;
			@$target = (
				[],
				{ map { $_ => $i++ } @{$meta->{names}} },
				$meta->{names},
			);
		}
		my $rec = [
			map {
				my $sub = (ref($_) eq 'CODE' ? $_ : $self->can($_));
				$self->$sub()
			}
			@{$meta->{functions}}
		];
		push @{ $target->[0] }, $rec;
		return $my_name;
	};

	sub to_itl_loop {
		my $self = shift;
		my ($targets, $loop_name, $relations);
		%$loop_counters = ();
		if (ref $self) {
			$targets = [ $self ];
			($loop_name, $relations) = @_;
		}
		else {
			($loop_name, $targets, $relations) = @_;
		}

		die 'Invalid loop name provided'
			unless $loop_name =~ /^[a-z0-9_]+$/i
		;

        $self->reset_itl_loops()
            unless defined $loops
                and defined $loop_data
                and defined $loop_meta
                and defined $loop_counters
        ;
        
		$self->$reset_loop( $loop_name, $relations );
		my $processing_info = $self->$resolve_associations( $relations );
        #print STDERR "resolved associations:\n" . Dumper($processing_info) . "\n\n";
		for my $item (@$targets) {
			$item->$itl_loop( $loop_name, '', @$processing_info{qw(base associations)} );
		}
	}

	sub get_itl_loop {
		my ($invocant, $name) = @_;
		return $loop_data->{$name};
	}

	sub get_all {
		return $loop_data;
	}

    sub reset_itl_loops {
        my $self = shift;
        no warnings 'once';
        my $base = $::Instance->{__PACKAGE__ . '_loop_repository'} = {};
        ($loops, $loop_data, $loop_meta, $loop_counters)
            = @$base{qw(loops data meta counters)}
            = ({}, {}, {}, {},)
        ;
        return;
    }
}

#**************************************

package IC::Model::Rose::Object::Manager;

use strict;
use warnings;

use Rose::DB::Object::Manager;
use base qw(Rose::DB::Object::Manager);

1;

__END__
