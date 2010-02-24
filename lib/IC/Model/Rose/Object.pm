package IC::Model::Rose::Object;

use strict;
use warnings;

use IC::Model::Rose::DB;

use Rose::DB::Object;
use base qw(Rose::DB::Object IC::Model);

# Make a _logger attribute with get_logger/set_logger accessors,
# which will fit nicely into the IC::Log::Logger paradigm inherited
# from IC::Model.

# use Rose tool for generating a "_logger" attribute.
use Rose::Object::MakeMethods::Generic (
    'scalar --get_set' => '_logger',
);

use Rose::Object::MakeMethods::Generic (
    hash => [
        tracked_columns => { interface => 'get_set_inited' },
    ],
);

use Rose::Class::MakeMethods::Set (
    inheritable_set => [
        observer => {
            test_method => 'observed_by',
        },
    ],
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

{
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

#
# TODO: we need to clearly pick a better delimiter than '_'
# method to consistently serialize a PK...
#
sub as_hashkey {
    my $self = shift;

    # C<sort> here just to force consistency
    return join '_', map { $self->$_ } sort @{ $self->meta->primary_key_columns };
}

#
# TODO: deserialization won't work so well when using '_' as the delimiter
# ... and a method to deserialize the hashed PK
#
sub from_hashkey {
    my $self = shift;
    my $hashkey = shift;

    my $hash = {};
    @$hash{ sort @{ $self->meta->primary_key_columns } } = split /_/, $hashkey;

    return; 
}

sub add_tracked_columns {
    my $self = shift;
    my $meta = $self->meta;
    for my $column (@_) {
        $meta->column($column)->add_trigger(
            code  => sub { shift->_track_column_value($column); },
            event => 'on_load',
        );
    }
}

sub _track_column_value {
    my ($self, $column) = @_;
    my $sub = $self->can( $self->meta->column_accessor_method_name($column) );
    return $self->tracked_columns->{$column} = $self->$sub();
}

sub boilerplate_columns {
    return (
        date_created          => { type => 'timestamp', default => 'now', not_null => 1 },
        created_by            => { type => 'varchar', default => '', length => 32, not_null => 1 },
        last_modified         => { type => 'timestamp', not_null => 1 },
        modified_by           => { type => 'varchar', default => '', length => 32, not_null => 1 },
    );
}

sub init_db {
    return IC::Model::Rose::DB->new;
}

sub transaction_aware_notification {
    my $self = shift;
    return unless $self->observers;

    return $self->notify_observers(@_) unless $self->db->in_transaction;

    my @args = @_;
    $self->db->add_commit_callbacks( sub { $self->notify_observers(@args) } );

    return 1;
}

sub save {
    my $self = shift;

    my $result = $self->SUPER::save(@_);
    $self->transaction_aware_notification('save');

    return $result;
}

sub insert {
    my $self = shift;

    my $result = $self->SUPER::insert(@_);
    $self->transaction_aware_notification('insert');

    return $result;
}

sub delete {
    my $self = shift;

    my $result = $self->SUPER::delete(@_);
    $self->transaction_aware_notification('delete');

    return $result;
}

sub update {
    my $self = shift;

    my $result = $self->SUPER::update(@_);
    $self->transaction_aware_notification('update');

    return $result;
}

#############################################################################
package IC::Model::Rose::Object::Manager;

use strict;
use warnings;

use Rose::DB::Object::Manager;
use base qw(Rose::DB::Object::Manager);

1;

__END__

=pod

=head1 NAME

B<IC::Model::Rose::Object> -- custom B<Rose::DB::Object>-derived baseclass for model classes wishing to use RDBO

=head1 SYNOPSIS

Largely just provides basic B<Rose::DB::Object> behaviors, with a few additions:

=over

=item *

Automatically initializes the database as needed to use B<IC::Model::Rose::DB>.

=item *

Class-method I<boilerplate_columns()> provides metadata for common columns (timestamp and user information).

=item *

Publisher/observable behavior: the I<observers> interface allows external observers to subscribe to
object-level state changes, for event-driven side-effects like cache management and such.

=item *

Tracked columns: specify per-model-class what columns you want to track, and their original (as loaded from
the db) values will be preserved in a hash.

=back

=head1 OBSERVERS INTERFACE

The I<observers> interface allows an external class to act as a subscriber to the following operations
for instances of the observed class:

=over

=item C<insert()>

=item C<update()>

=item C<save()>

=item C<delete()>

=back

In each case, all observers registered with the relevant class are notified of the operation taking
place.  This means that the observer (which is assumed to be a package/class name) has its I<update()>
method invoked, and is passed the B<IC::Model>-derived instance and the name of the method invoked
(from the above list).

Because a C<save()> will ultimately invoke either an C<insert()> or an C<update()>, you will find that
C<save()> invocations result in two invocations of the observer.

The notification can be transaction-aware; if the above methods are invoked within a transaction, and the
B<IC::Model> is transaction-aware, then C<commit_callbacks()> functionality is used such that notification 
only occurs after the transaction succeeds.  This means that notification may be delayed by some time relative to
its corresponding causal method invocation.

Outside a transaction, the notifications are immediate.

You can manipulate observers with various methods:

=over

=item C<add_observer( $classname )>

This will add C<$classname> as an observer of the relevant B<IC::Model> subclass.  Similarly,
you can use C<add_observers> (plural) and specify multiple observers to add.

=item C<observed_by( $classname )>

Returns true/false based on the presence/absence of C<$classname> in the observers list for class.

=item C<observers()>

Returns the list of observers in no particular order.  In scalar context returns an arrayref of the
observers

=item C<delete_observer( $classname )>

Removes C<$classname> from the observers list.  Like "add_", you can pluralize this and specify
multiple classnames.

=back

A basic example: suppose C<MyApp::Cache> manages a cache for MyApp::Model instances, and we want to
use this behavior to keep the cache accurate.

 package MyApp::Model;
 use base qw(IC::Model::Rose::Object);
 # ...assume the usual Rose metadata blather...
 
 package MyApp::Cache;
 # ...cache management particulars to skip
 
 # update method is invoked at notification time
 sub update {
     my ($self, $rose_obj, $action) = @_;
     # an update or a delete requires clearing the cache.  Other actions
     # can be ignored and let the cache get built on demand.
     $self->clear_cache_by_key( $rose_obj->id )
         if $action eq 'delete' or $action eq 'update';
 }
 
 # now subscribe this to the model class
 MyApp::Model->add_observer( __PACKAGE__ );

There you go.

This interface is noisy and low-level, rather akin to row-level triggers versus statement-level
triggers.  The Manager interface bypasses this stuff entirely, and your observers only get visiblity
into individual instance operations rather than groups of operations.

=head1 TRACKED COLUMNS

The column-tracking mechanism allows you to see, after changing the attributes of an instance,
what the values originally loaded into the tracked columns were prior to changing.

These are only populated at load time, and only preserved for the columns specified on a given
model class.  They are not updated by update operations; you would need to reload the object to get
the freshen db values in ther.

=over

=item B<add_tracked_columns( @column_names )>

Class method: invoke on your model class and give names of columns you want tracked in the manner described above.

=item B<tracked_columns()>

Instance method: returns a hashref where the keys correspond to the column names of the tracked columns for
the instance's class.  The values are the original (raw) values from the database for those columns as they
were at load time.

=back

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
