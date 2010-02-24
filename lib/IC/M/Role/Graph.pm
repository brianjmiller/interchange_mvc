package IC::M::Role::Graph;

use IC::Cache;
use IC::M::Role;
use IC::M::Role::HasRole;

use Moose;

with 'IC::M::Graph::Cache';

has db => (
    is => 'rw',
    required => 1,
);

has cacher => (
    is => 'rw',
    lazy => 1,
    default => sub {
        IC::Cache->new;
    },
);

sub fetch_relations {
    #
    # TODO: shouldn't (can't?) this be done with get_objects
    #
    return shift->db->dbh->selectall_arrayref(
        q(
            SELECT
                r.id,
                hr.has_role_id
            FROM
                ic_roles r
            LEFT JOIN
                ic_roles_has_roles hr ON hr.role_id = r.id
        )
    );
}

sub clear_cache {
    my $self = shift;

    return $self->cacher->delete(__PACKAGE__);
}

sub build_cache {
    my $self = shift;
    my ($map) = @_;

    return if $self->db and $self->db->in_transaction;

    #
    # TODO: make this configurable
    #

    # lives for 10 minutes
    return $self->cacher->set(__PACKAGE__, $map, 600);
}

sub retrieve_cache {
    my $self = shift;

    return if $self->db and $self->db->in_transaction;

    return $self->cacher->get(__PACKAGE__);
}

# heavy-handed, but clear cache for any state changes in role-space
sub update {
    my $class = shift;
    my ($obj, $action) = @_;

    $class->new(db => $obj->db)->clear_cache();
}

$_->add_observer(__PACKAGE__) for qw( IC::M::Role IC::M::Role::HasRole );

1;

=pod

=head1 NAME

IC::M::Role::Graph -- A class providing DAG navigation
for the roles subsystem

=head1 SYNOPSIS

Provides the DAG interface of B<IC::M::Graph>; refer to
that documentation for an outline of the navigational interface.

The constructor requires that the I<db> attribute be provided with
a B<Rose::DB::Object>-derived instance.

=head1 EXAMPLE

 my $graph = IC::M::Role::Graph->new( db => IC::Model::Rose::DB->new );
 $graph->no_references();
 ...and so on

=head1 BLAME

It's Ethan's fault.

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
