package IC::M::Right;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table       => 'ic_rights',
    columns     => [
        id            => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_rights_id_seq' },

        __PACKAGE__->boilerplate_columns,

        role_id       => { type => 'integer', not_null => 1 },
        right_type_id => { type => 'integer', not_null => 1 },
        is_granted    => { type => 'boolean', not_null => 1 },
    ],
    unique_key  => [
        [ qw( role_id right_type_id is_granted ) ],
    ],
    foreign_keys    => [
        right_type  => {
            class       => 'IC::M::RightType',
            key_columns => { right_type_id => 'id' },
        },
        role        => {
            class       => 'IC::M::Role',
            key_columns => { role_id => 'id' },
        },
    ],
    relationships   => [
        targets => {
            type       => 'one to many',
            class      => 'IC::M::RightTarget',
            column_map => { id => 'right_id' },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;

    return $self->right_type->description . ' for ' . $self->role->display_label || $self->id || 'Unknown Right';
}

1;

__END__

=pod

=head1 NAME

B<IC::M::Right>: model fronting rights data and operations

=head1 DESCRIPTION

The rights operations follow these general rules:

=over

=item *

default deny

=item *

explicit grants

=item *

explicit denies, to override inherited grants

=item *

a right is attached to a specific role, determined by the I<role> foreign key attribute (an instance of B<IC::M::Role>)

=item *

rights are inherited through the role graph; if role B references role A, then role B inherits all of role A's rights.

=item *

a right object (B<IC::M::Right>)'s I<is_granted> attribute determines whether it represents a grant (true) or deny (false).

=item *

a right always has a right type (I<right_type> foreign key attribute, returning an instance of B<IC::M::RightType>).

=back

=head2 RIGHT TYPES

The right type determines the semantic meaning of the right in question; the right type's I<code> attribute determines the basic name of the right, while the I<target> attribute determines what structure (if any) rights of that type reference.  A right type with a non-null I<target> means that the right type does not merely have a code, but will grant/deny that named privilege to some other structure.  For such right types, a right is not complete without its accompanying target data, and the B<IMPLEMENTING RIGHTS TARGETS> section will explain how this is achieved.

=head2 RIGHT SPECIFICITY AND GENERATIONAL CONFLICT RESOLUTION

The roles data allows for full directed graphs rather than mere hierarchies; put another way, this is rather like allowing multiple inheritance rather than single inheritance.  Any role can consume any number of other roles, meaning that the same role may appear multiple times in the full set of some role's ancestors.  Furthermore, since grants and denies can be attached to any role, it is possible for conflicts to occur for a given right type (and optional target).

Consequently, we use an algorithm that addresses this, with the following assumptions:

=over

=item Smallest generational distance wins

When considering rights for a given role, we consider the generational distance between the role in question and the ancestor role to which a right is attached.  For any N right_type/target combination instances for all ancestors of the role in question, the one(s) with the smallest generational distance win.

=item Grants must be anonymous within the winning generation

Whatever the smallest generational distance may be, it is still possible that multiple rights instances will be found for the role/right_type/target in question.  Consequently, the right is only granted if all rights instances of that same generation are grants; any single deny means a result of deny.

=back

Consequently, to determine if role X, with ancestor roles B and C, both of which have ancestors role A, has right type 10, we:

=over

=item *

Look for rights records of right_type 10 for role X.

=item *

If any such right is found, we're done, and the is_granted value determines the result.   If no rights are found, keep going.

=item *

Look for rights records of right_type 10 for roles B and C (iterative through generations, rather than purely recursive)

=item *

Rights found?  Look for !is_granted; any occurence of !is_granted means deny; if only true is_granted values are found, grant the right.  No rights found?  Then keep going.

=item *

Look for rights records of right_type 10 for role A (the top generation in this example).

=item *

Rights found?  Resolve is_granted/!is_granted as before.  No rights found?  Keep going.

=item *

Role A consumes no roles, so nothing further to do.  The right is denied.

=back

=head1 IMPLEMENTING RIGHTS TARGETS

To tie into the rights system so your structures can be treated as rights targets, thus enabling access control to them, you need some model classes to front the stuff and implement a few basic things:

=over

=item right_types target allowance

The constraint on the target column of the right_types table must allow for a value that identifies the right type as pertaining to your target.

=item target linking table

A table that links rights records to the structures you're trying to tie in as a right target.  Assuming that your structures have a simple primary key, all that's really needed is a foreign key to the rights table and a foreign key to your target structure table.

A postgres trigger function is available to help ensure that any records included in your linking table refer to rights of the appropriate type.  Put an INSERT/UPDATE trigger (before or after, either should work) on your table that executes the I<rights_enforce_target_type('type_name')> function, where I<'type_name'> is the name you use for identifying your target type in the right_types table target column.  The trigger function will throw an exception if a record in your linking table references a right of incorrect type.

=item Rose::DB::Object classes fronting your linking table and target table.

This really goes without saying at this point, right?

=item one-to-many Rose::DB::Object relation from B<IC::M::Right> to your target table

Extend B<IC::M::Right> so it has a one-to-many relationship with your linking table's appropriate Rose class.  This will allow you to tie your table into the queries used for rights lookup.

=item implement methods to tie into the rights lookup procedures

Here's the nitty-gritty stuff that'll make everything magically deliciously special.

Within your Rose class fronting your linking table, implement:

=over

=item I<implements_type_target()>

This should return the value for the target column in the I<right_types> table for which your linking table is relevant.

=item I<target_relationship()>

This should return the name of the relationship you used when extending B<IC::M::Right> above, it is the one-to-many relationship used to find target records. 

=item I<target_influencers( $targets, $graph )>

Given an array ref in I<$targets> containing a list of objects that will be checked for a particular right, this method should return a prioritized list of targets that can influence the outcome for a particular target via a hash ref keyed on the target's PK as returned by B<as_hashkey()>. (More on as_hashkey is mentioned below.) The values of the hash ref should be array references pointing to arrays whose elements themselves are arrays of PKs as returned by B<as_hashkey()> of targets that influence the outcome for the target in question. The outer list should be prioritized such that the elements closer to an index of 0 are of higher priority than those further away from 0.

The I<$graph> is an instance of B<IC::M::Role::Graph>, which allows your target_influencers implementations
to work with the same realized graph of roles (as needed) as the main right check routine uses.  For most
implementations this likely doesn't matter, but for any target that needs to consider roles, this can bring
a significant performance gain and, at least as critically, a view of the role DAG consistent with that of
the main right check routine itself.

=back

Then, finally, in the Rose class that fronts your actual target structure, implement the following:

=over

=item I<rights_class()>

Return the name of the Rose class that fronts your linking table.  This will mean that instances of your target structure class
can be passed as target to I<check_right>, and the right lookup will know how to tie things together.

This ought to be implemented to function properly when invoked as class method or instance method.

=item I<as_hashkey()>

An instance method that should return a hashkey-friendly key that could uniquely identify the target instance within a hash.  Assume that the hash would have no other types of stuff in it,
so you don't need to concern yourself with namespaces, colliding with other hashkey schemes, etc.

This method will be used by the rights lookup algorithm for organizing target sets and target results, and will be helpful for your own target implementations as well.

The B<IC::Model::Rose::Object> base class provides a method that should be sensible in most cases (when the model is RDBO based). But as an example, simple classes with a basic primary key named, say, I<id>, a sensible definition would be:

 sub as_hashkey {
     return shift->id;
 }

=back

For example implementations, see B<IC::M::Right::Role> and B<IC::M::Right::SiteMgmtFunc>.

=back

This probably sounds more complicated than it actually is.

=head1 INTERFACE

For information on accessing into the rights system see B<IC::M::Role>'s check_right() method.

=head1 CREDITS

Blame Ethan. Then yell at Brian.

=cut

