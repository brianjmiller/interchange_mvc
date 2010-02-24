package IC::M::Role;

use strict;
use warnings;

use IC::M::RightTarget::Role;

use base qw( IC::Model::Rose::Object );

use IC::M::Role::Walker;
use IC::M::Role::Graph;

__PACKAGE__->meta->setup(
    table           => 'ic_roles',
    columns         => [
        id            => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_roles_id_seq' },

        __PACKAGE__->boilerplate_columns,

        code          => { type => 'varchar', not_null => 1, length => 50 },
        display_label => { type => 'varchar', not_null => 1, length => 100 },
        description   => { type => 'text', not_null => 1, default => '' },
    ],
    unique_key      => 'code',
    relationships   => [
        has_roles   => {
            type        => 'many to many',
            map_class   => 'IC::M::Role::HasRole',
            map_from    => 'role',
            map_to      => 'has_role',
        },
        roles_using => {
            type        => 'many to many',
            map_class   => 'IC::M::Role::HasRole',
            map_from    => 'has_role',
            map_to      => 'role',
        },
        rights      => {
            type        => 'one to many',
            class       => 'IC::M::Right',
            column_map  => { id => 'role_id' },
        },
        users       => {
            type        => 'one to many',
            class       => 'IC::M::User',
            column_map  => { id => 'role_id' },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Role');
}

sub rights_class { 'IC::M::RightTarget::Role' }

sub roles_referenced_by {
    my ($invocant, $set, $db) = @_;

    my @ids = map { $_->id } @$set;
    my %arg = (
        require_objects => [ 'roles_using' ],
        query           => [
            'roles_using.id' => \@ids,
        ],
    );

    $arg{db} = $db if $db;

    return IC::M::Role::Manager->get_objects(%arg);
}

sub has_role {
    my ($self, $role, $generation) = @_;

    my $walker = IC::M::Role::Walker->new(
        roles => [ $self ],
    );

    my ($result, $found, $current_generation);
    while ($walker->next) {
        next unless $walker->generations->[$current_generation++]->{$role->id};

        $found++;

        last unless $generation;

        push @{$result ||= []}, $current_generation;
    }

    return $generation ? $result : $role if $found;
    return;
}

sub has_role_by_name {
    my $self = shift;
    my $code = shift;

    my $check_role = __PACKAGE__->new( code => $code )->load;

    return $self->has_role($check_role, @_);
}

#
# TODO: switch this to be a relationship method on the user model
#       rename as user_roles implies roles that have 'user',
#       but it really should be roles that users link to
#
sub user_roles {
    my $invocant = shift;
    my %opt = (
        require_objects => [ 'role' ],
        sort_by         => 'display_label',
    );
    if (@_) {
        $opt{db} = shift;
    }
    elsif (ref $invocant) {
        $opt{db} = $invocant->db;
    }

    return [ map { $_->role } IC::M::User::Manager->get_objects( %opt ) ];
}

#
# TODO: improve this name cause it still isn't right
#
sub roles_with_right {
    my $self = shift;
    my $right = shift;

    return $self->check_right( $right, IC::M::Role::Manager->get_objects );
}

sub check_right {
    my $self = shift;

    my $right_code     = shift;
    my $targets        = shift;
    my $role_graph_obj = shift || IC::M::Role::Graph->new( db => $self->db );

    unless (defined $right_code and $right_code ne '') {
        IC::Exception->throw('Cannot check right: right_code not provided');
    }

    #warn "Called check_right: $right_code (" . $self->display_label . ") ((" . $self->id . "))\n";

    #
    # store a quick access list of targets, accesssible by the PK
    #
    my $targets_by_pk;

    #
    # pre-process the list of targets, make sure they are all of the same type,
    # determine whether we have multiple targets to check, and get a prioritized
    # list of all targets that can influence the decision about a target in question
    #

    my $target_class;
    my $many_targets;
    my $target_influencers;
    if (defined $targets) {
        $many_targets = ref $targets eq 'ARRAY';
        if ($many_targets) {
            return [] unless @$targets;
        }
        else {
            $targets = [ $targets ];
        }

        #
        # make sure all passed in targets have the same target class
        #
        $target_class = $targets->[0]->rights_class;

        for my $target (@$targets) {
            unless ($target->rights_class eq $target_class) {
                IC::Exception->throw( q{Cannot check right: inconsistent target types '} . $target->rights_class . "' != $target_class");
            }
        }

        $targets_by_pk = {
            map { $_->as_hashkey => $_ } @$targets
        };

        #
        # this is basically a cache of a list of lists of targets that
        # can influence the determination of a target's rights, it should
        # be sorted such that higher priority influencing targets appear
        # earlier in the list (aka closer to index 0)
        #
        # we build a single cache structure here so that the build process
        # can be leveraged across all of the targets that we are interested
        # in to gain significant performance improvements
        #
        $target_influencers = $target_class->target_influencers( $targets, $role_graph_obj );
        #warn "Target influencers for " . join( ', ', keys %$targets_by_pk) . ": " . Dumper($target_influencers) . "\n";
    }
    else {
        $target_class = 'IC::M::RightTarget';
        $targets_by_pk = { '' => undef };
    }

    #
    # all targets need a result, create a map with undef
    # then any targets without a defined result can still
    # be checked
    #
    my $target_grant_or_deny_map = { map { $_ => undef } keys %$targets_by_pk };

    my $target_type = $target_class->implements_type_target;

    my $right_type = IC::M::RightType->new(
        db               => $self->db,
        code             => $right_code,
        target_kind_code => $target_type,
    )->load;

    #
    # initially check just our role but setup a graph
    # to allow generational walking if necessary
    #
    my $role_graph = $role_graph_obj->references($self->id);
    my @check_roles = @{shift(@$role_graph) or []};

    #
    # initially check all targets
    #
    my @check_target_pks = keys %$target_grant_or_deny_map;

    #my $target_relationship = $target_class->target_relationship;

    while (@check_roles) {
        #warn "checking roles: " . join(', ', @check_roles) . "\n";

        my $rights = [
            $right_type->find_rights(
                #(defined $with_objects ? ( with_objects => $with_objects ) : ()),
                query => [
                    role_id => [ @check_roles ],
                ],
            ),
        ];
        #warn "\tfound rights: " . @$rights . "\n";

        if (@$rights) {
            #
            # associate targets with rights to prevent need
            # to find targets more than once
            #
            my $rights_target_cache = {};
            for my $right (@$rights) {
                if (defined $right->right_type->target_kind_code) {
                    for my $right_target (@{ $right->targets }) {
                        $rights_target_cache->{$right_target->ref_obj_pk}->{$right->id} = $right;
                    }
                }
                else {
                    $rights_target_cache->{''}->{$right->id} = $right;
                }
            }

            for my $target_pk (@check_target_pks) {
                my $determining_rights;

                if (exists $rights_target_cache->{$target_pk}) {
                    $determining_rights = [ values %{ $rights_target_cache->{$target_pk} } ];
                }
                else {
                    my $target = $targets_by_pk->{$target_pk};
                    #warn "working on target: $target_pk\n";

                    #
                    # need a list of possible targets that could influence this right decision
                    #
                    #warn "target influencers for target $target_pk: $target_influencers->{$target_pk}\n";
                    my @influential_target_refs = @{ $target_influencers->{$target_pk} };

                    for my $influencing_target_ref (@influential_target_refs) {
                        for my $influencer (@$influencing_target_ref) {
                            if (exists $rights_target_cache->{ $influencer }) {
                                push @$determining_rights, values %{ $rights_target_cache->{ $influencer } };
                            }
                        }

                        last if defined $determining_rights and @$determining_rights;
                    }
                }

                if (defined $determining_rights and @$determining_rights) {
                    if (grep { ! $_->is_granted } @$determining_rights) {
                        $target_grant_or_deny_map->{$target_pk} = 0;
                    }
                    else {
                        push @{ $target_grant_or_deny_map->{$target_pk} }, @$determining_rights;
                    }
                    next;
                }
            }
        }

        @check_target_pks = ();
        while (my ($key, $val) = each %$target_grant_or_deny_map) {
            next if defined $val;

            push @check_target_pks, $key;
        }
        last unless @check_target_pks;

        @check_roles = @$role_graph ? @{shift @$role_graph} : ();
    }

    #
    # any non-determined targets are denied
    #
    while (my ($key, $val) = each %$target_grant_or_deny_map) {
        next if defined $val;

        $target_grant_or_deny_map->{$key} = 0;
    }

    #
    # return nothing unless something is granted
    #
    return unless grep { $_ } values %$target_grant_or_deny_map;

    if (defined $targets and @$targets) {
        if ($many_targets) {
            return [ map { $targets_by_pk->{ $_ } } grep { $target_grant_or_deny_map->{$_} } keys %$target_grant_or_deny_map ];
        }
        else {
            return $target_grant_or_deny_map->{$targets->[0]->as_hashkey};
        }
    }
    else {
        return $target_grant_or_deny_map->{''};
    }

    return;
}

1;

__END__

=pod

=head1 NAME

B<IC::M::Role>: model fronting roles

=head1 DESCRIPTION

Roles represent a DAG.

=head1 RIGHTS

check_right() is provided to tie into the rights system as described by B<IC::M::Right>.

=over

=item $role->check_right( $right, $target [ , $graph ] )

When called on an instance of B<IC::M::Role> (I<$role>), and given a right type code I<$right>, and optional target structure I<$target>, determines whether or not I<$target> has the I<$right> in question for I<$role>.

The I<$graph> is an optional instance of B<IC::M::Role::Graph>.  If not provided, one wil be created
internally.  If one is available, then passing it around is useful as a performance optimization and to
give a consistent (serialized-style) view of the roles.

The I<$target> may be either:

=over

=item *

An instance of some class that implements the rights target interface

=item *

An arrayref of instances of some class that implements the rights target interface.  In this case, all members of the arrayref must implement the same
target type; an exception is thrown otherwise.

=item *

Undef or an empty arrayref, in which case this is a check for a "simple" right with no target at all.

=back

If the right code is not granted to I<$role> for any I<$target>, then this returns nothing.

If the right is granted and I<$target> was a single instance (not an arrayref), then the result will be an arrayref of rights objects that grant the right in question.

If I<$target> was an arrayref of one or more instances and the right is granted to at least one of the set, then the result will be the list of I<$target> members to which the right is granted.

When a scalar I<$target> is used, the rights objects included in the resulting arrayref will indicate their associated role, making it possible to determine
where in the role graph a role gets rights from.  However, when a right is not granted, it is not possible to discern the reason
from the output of this method; explicit denials and implicit denials appear the same.  This is by design.

=back

=head1 CREDITS

Blame Ethan. Then yell at Brian.

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

