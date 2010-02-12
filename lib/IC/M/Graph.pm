package IC::M::Graph;

use Moose::Role;

requires 'fetch_relations';

has _map => (
    is => 'rw',
    lazy => 1,
    default => sub {
        shift->initialize_map;
    },
);

sub initialize_map {
    my $self = shift;

    my ($mapping, $referer, $reference);
    $mapping = {
        referer   => $referer = {},
        reference => $reference = {},
    };

    for my $ref (@{ $self->fetch_relations }) {
        my ($id, $refid) = @$ref;
        my $out = $reference->{$id};
        unless (defined $out)  {
            $out = $reference->{$id} = [];
            $referer->{$id} ||= [];
        }

        if (defined $refid) {
            push @$out, $refid;
            push @{$referer->{$refid} ||= []}, $id;
        }
    }

    return $mapping;
}

sub _referer_map {
    return shift->_map->{referer};
}

sub _reference_map {
    return shift->_map->{reference};
}

sub _no_relations {
    my ($self, $map) = @_;
    return [ sort {$a <=> $b } grep { !@{$map->{$_}} } keys %$map ];
}

sub no_referers {
    my $self = shift;
    return $self->_no_relations( $self->_referer_map );
}

sub no_references {
    my $self = shift;
    return $self->_no_relations( $self->_reference_map );
}

sub _generational_map {
    my $self = shift;
    my %opt = @_;
    my ($map, $set, $seen) = @opt{qw( mapping set seen )};
    $seen ||= {};
    my @set = @$set;
    my @result;
    do {
        my @candidates = grep {!$seen->{$_}++ and defined($map->{$_})} @set;
        push @result, \@candidates if @candidates;
        @set = map { @$_ } @{$map}{@candidates};
    }
    while (@set);
    return \@result;
}

sub referers {
    my $self = shift;
    return $self->_generational_map(
        mapping => $self->_referer_map,
        set     => \@_,
    );
}

sub references {
    my $self = shift;
    return $self->_generational_map(
        mapping => $self->_reference_map,
        set     => \@_,
    );
}

sub explode {
    my $self = shift;
    my $id = shift;
    my $seen = {};
    my $references = $self->_generational_map(
        mapping => $self->_reference_map,
        set     => [$id],
        seen    => $seen,
    );
    my $referers = $self->_generational_map(
        mapping => $self->_referer_map,
        set     => [$id],
        seen    => $seen,
    );
    shift @$referers;
    return [ reverse(@$referers), @$references ];
}

sub _relation_check {
    my $self = shift;
    my %opt = @_;

    my ($is_final, $no_result, $seen);

    if (defined $opt{generations}) {
        $is_final = (--$opt{generations} < 1);
        $no_result = 1 if $opt{exact} and !$is_final;
    }
    else {
        $seen = $opt{seen} ||= {};
    }

    my %set = map { $_ => 1 }
        grep { !defined($seen) or !$seen->{$_}++ }
        map { @$_ } @{$opt{mapping}}{@{$opt{source}}};
    
    if (%set and !$no_result) {
        my @new_targets;
        for my $target (@{$opt{targets}}) {
            if (exists $set{$target}) {
                push @{$opt{results}}, $target;
            }
            else {
                push @new_targets, $target;
            }
        }
        $opt{targets} = \@new_targets;
    }

    return $opt{results} || []
        if $is_final or !%set or !@{$opt{targets}};

    $opt{source} = [keys %set];
    return $self->_relation_check(%opt);
}

sub has_reference {
    my $self = shift;
    my %opt = @_;
    $opt{source} = [delete $opt{node}];
    return $self->_relation_check(
        %opt,
        mapping => $self->_reference_map,
    );
}

sub has_referer {
    my $self = shift;
    my %opt = @_;
    $opt{source} = [delete $opt{node}];
    return $self->_relation_check(
        %opt,
        mapping => $self->_referer_map,
    );
}

1;

__END__

=pod

=head1 NAME

IC::M::Graph -- a class providing navigational
tools for directed graphs

=head1 SYNOPSIS

This Moose::Role provides navigational logic for directed acyclic
graphs (DAGs), of which traditional trees/hierarchies are a strict
subset.

B<IC::M::Graph> builds an in-memory map of the
entire graph relationship structure and provides a simple
object interface for walking and exploding out the graph in various ways.

To use this role, your class need only implement a method that returns the list
of id-to-id references.

=head1 EXAMPLE

Our class needs to implement a method that returns mapping information for
the graph in question.

 package IC::M::ThingThatUses::Graph;
 use Moose;
 with 'IC::M::Graph';
 
 # let's say this class uses the DB to get the map; it needs
 # a database handle.
 has db => (
     is => 'rw',
     default => sub { IC::Model::Rose::DB->new },
     lazy => 1,
 );
 
 # fetch_relations is used by IC::M::Graph
 # to build its map
 sub fetch_relations {
     my $self = shift;
     return $self->db->dbh->fetchall_arrayref(q(
         SELECT node_id, reference_node_id
         FROM node_map
     ));
 }

Assume you have node structures like so:

=over

=item *

Node 1 has nodes 2 and 3

=item *

Node 2 has nodes 4 and 5

=item *

Node 3 has node 6

=item *

Node 7 has node 6

=back

Then you might see things like:

 # get the graph
 my $graph = IC::M::ThingThatUses::Graph->new();

 # get the full graph referenced by node 1
 $graph->references(1);
 # would yield generational id list result like:
 # [
 #   [1],
 #   [2, 3],
 #   [4, 5, 6],
 # ]

 # get the graph of nodes that refer to node 6
 $graph->referers(6);
 # [
 #   [6],
 #   [3, 7],
 #   [1],
 # ]

So, note in the above that:

=over

=item *

The I<references> are for things that the given node points
to, or "has".

=item *

The I<referers> are things that point to the given node, or that "have" that node.

=item *

For these graph lists, we always include the identity first.

=item *

Each subarray denotes an additional generation of indirection.

=back

Some other examples:

 # all the nodes that do not reference anything
 $graph->no_references;
 # [4, 5, 6]
 
 # all the nodes that are not referenced by anything
 $graph->no_referers;
 # [1, 7]
 
 # which of the following does 1 reference?
 $graph->has_reference(
      node => 1,
      targets => [4, 5, 6, 7],
 );
 # result: [4, 5, 6]
 
 # how many are within 2 generations?
 $graph->has_reference(
     node => 1,
     targets => [4, 5, 6],
     generations => 2,
 );
 # result: [4, 5]
 
 # how about within 1 generation?
 $graph->has_reference(
     node => 1,
     targets => [4, 5, 6],
     generations => 1,
 );
 # result: []
 
 # how about exactly 3 generations?
 $graph->has_reference)
     node => 1,
     targets => [4, 5, 6],
     generations => 3,
     exact => 1,
 );
 # result: [6]

=head1 CONSTRUCTOR AND INITIALIZATION

The constructor does not require anything by default.

=over

=item B<new( %param )>

=back

The constructor behaves as one would expect, except that
it does not immediately build its in-memory map.  Instead, the
map is initialized on-demand (first use).

Any of the methods documented below will cause initialization
of the graph map.

Once initialized, that representation of the graph data is
used for the lifetime of the instance.

=head1 REQUIREMENTS

=over

=item B<fetch_relations()>

B<IC::M::Graph> uses B<fetch_relations()> to build its internal
map.

The expectation is that:

=item *

An arrayref of arrayrefs is returned

=item *

Each inner arrayref represents a single mapping from one node id to another node id, with
the first id (position 0) referring to the second id (position 1).

=item *

Any node that exists but does not reference another should be included in one of these inner
arrayrefs, in position 0, with position 1 undef.

=back

=head1 METHODS

=over

=item B<references( @ids )>

Returns an arrayref of arrayrefs, with each nested array
representing a generation's indirection from I<@ids>.
The generations are flattened such that the branches that
constitute a given generation are collapsed into the
single generation list.

The identity list is always the first subarray.

=item B<referers( @ids )>

Exactly akin to B<references()>, with same result structure,
except it represents referers to I<@ids> rather than nodes
referenced by I<@ids>.

=item B<no_references()>

Returns ordered list of ids for all known nodes that do
not reference any other.

=item B<no_referers()>

Returns ordered list of ids for all known nodes that are
not referenced by any other.

=item B<has_reference( %param )>

Given a list of target node ids, and a source node id,
returns an arrayref containing the subset of target ids
to which the source node refers.

By default, generational distance is disregarded; any
number of generations will be walked until no further
relationships remain or all targets have been located.
However, this can be controlled using the I<generations>
and I<exact> parameters.

The result set will I<not> include the identity in this
case.

Valid values for I<%param>:

=over

=item I<node> => I<node_id>

The id of the "source node" the references of which we're
examining.  Required.

=item I<targets> => [ I<role1>, I<role2>, ... I<roleN> ]

The arrayref of node ids to be tested for a reference from
I<node>.  Required.

=item I<generations> => I<num_generations>

If provided with a positive integer value, the result
will only include the subset of I<targets> that were found
within I<generations> of the I<node>.

=item I<exact> => I<true>

Must be used in combination with I<generations>; when
specified, the result will only include the subset of
I<targets> that are exactly within I<generations> of
I<node>.

=back

=item B<has_referer( %param )>

Exactly equivalent to I<has_reference>, supporting the
same arguments with the same behavior, excepting that
the relationships walked are referer relationships; this
returns ids of node.

=back

=head1 BLAME

Blame should be cast upon whoever I<git blame> points
you to.  Which will probably be me.

=cut
