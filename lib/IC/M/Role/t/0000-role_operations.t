#!/usr/local/bin/perl

use strict;
use warnings;

use Interchange::Deployment;
use IC::M::ManageFunction;

use Test::More tests => 47;

my (
    $role_class,
    $right_class,
    $right_type_class,
    $has_role_class,
    $site_mgmt_func_class,
    $right_target_class,
);
BEGIN {
    (
        $role_class,
        $right_class,
        $right_type_class,
        $has_role_class,
        $site_mgmt_func_class,
        $right_target_class,
    ) = map {
        'IC::M::' . $_
    }
    qw(
        Role
        Right
        RightType
        Role::HasRole
        ManageFunction
        RightTarget
    );

    use_ok($role_class);
}

=pod

=head1 TEST DATA

The test data does not assume any particular IDs.  It sets up roles with a particular
set of relationships but allows the IDs to come from database sequences, per usual.

The structures created:

  F-->D-->B
  |   |
  v   |
  E   |
  |   |
  v   v
  C-->A

A and B are "top" roles in that they do not reference any others.

This structure lets us verify multi-generational relationships between roles.

We will express the relationships, from a testing perspective, with the syntax I<XYn>,
where I<X> is the starting role and I<Y> is a role referenced by optional I<n> generations.

This full syntax:
 [ ! ] X Y [ n ]

The optional leading bang indicates that the relationship does not exist.  The optional trailing
number for generations has greater implications than a specific generational check; if not provided,
then the expression means that a relationship exists (or does not) at all, regardless of generation.

=head1 TEST HELPERS

=over

=item B<has_relationship( %$role_map, $relationship, $test_name )>

Will pass/fail depending on whether the roles in the test data (as represented in the hashref
I<$node_map>) contain the relationship expressed by string I<$relationship>.  This exercises
the B<has_role> method of B<IC::M::Role>, but wraps it with convenient syntax.

The I<$relationship> string should follow the syntax described above.

=item B<assert_right( %opt )>

Given various parameters in I<%opt>, runs a series of tests to validate the conditions per role.  Parameters
in I<%opt> may be:

=over

=item I<test>

The base name of the set of tests.

=item I<code>

The type code for the rights_type to assert.

=item I<target>

An optional target object that serves as the rights target for the rights check.

=item I<roles>

An arrayref listing roles to check; the role name ('A' through 'F') should correspond to a role in the chart above.

Presence in the list implies a positive assertion, unless the id is preceeded by a bang ('!'), in which case it is assumed to be a negative assertion.

Each role listed results in one test of the has_right() method.

=back

=back

=cut

my (
    $role_map,
    $site_mgmt_funcs,
    $right_type_simple,
    $right_type_role,
    $right_type_site_mgmt_func,
);
$role_map = test_roles();
my $db    = $role_map->{A}->db;

# no transaction, so wrap, catch errors, clear generated data.
eval {
    diag("Relationship Checks");
    has_relationship($role_map, @$_) for (
        ['CA', 'C has A'],
        ['CA1', 'C has A with 1 generation'],
        ['!AC', 'A does not have C'],
        ['!AB', 'A does not have B'],
        ['DA', 'D has A'],
        ['DA1', 'D has A with 1 generation'],
        ['DB', 'D has B'],
        ['DB1', 'D has B with 1 generation'],
        ['EC', 'E has C'],
        ['EC1', 'E has C with 1 generation'],
        ['EA', 'E has A'],
        ['EA2', 'E has A with 2 generations'],
        ['!EA1', 'E does not have A in 1 generation'],
        ['!EB', 'E does not have B'],
        ['!BE', 'B does not have E'],
        ['FD', 'F has D'],
        ['FD1', 'F has D in 1 generation'],
        ['FB', 'F has B'],
        ['FB2', 'F has B in 2 generations'],
        ['!FB1', 'F does not have B in 1 generation'],
        ['FA', 'F has A'],
        ['FA2', 'F has A in 2 generations'],
        ['FA3', 'F has A in 3 generations'],
        ['!FA1', 'F does not have A in 1 generation'],
        ['FB', 'F has B'],
        ['FB2', 'F has B in 2 generations'],
        ['!FB1', 'F does not have B in 1 generation'],
    );

    $right_type_simple         = $right_type_class->new( code => 'foo', display_label => 'Foo', target_kind_code => undef, db => $db )->save;
    $right_type_role           = $right_type_class->new( code => 'foo', display_label => 'Foo', target_kind_code => 'role', db => $db )->save;
    $right_type_site_mgmt_func = $right_type_class->new( code => 'foo', display_label => 'Foo', target_kind_code => 'site_mgmt_func', db => $db )->save;

    diag("Rights Check by Groups");
    diag("Group One");
    assert_right(
        roles   => [qw( !A !B !C !D !E !F )],
        code    => 'foo',
        test    => 'no rights for any role prior to grants',
        role_map    => $role_map,
    );

    diag("Group Two");
    $right_class->new( right_type_id => $right_type_simple->id, role_id => $role_map->{A}->id, db => $db, is_granted => 't' )->save;
    assert_right(
        code    => 'foo',
        test    => 'A and all referents get simple right',
        roles   => [qw( A !B C D E F )],
        role_map    => $role_map,
    );

    diag("Group Three");
    $right_class->new(
        right_type_id => $right_type_simple->id,
        role_id       => $role_map->{C}->id,
        is_granted    => 'f',
        db            => $db,
    )->save;
    assert_right(
        code        => 'foo',
        test        => 'C and referents denied simple right',
        role_map    => $role_map,
        roles       => [qw( A !B !C D !E !F )],
    );

    diag("Group Four");
    $right_class->new(
        right_type_id   => $right_type_simple->id,
        role_id         => $role_map->{D}->id,
        db              => $db,
        is_granted      => 't',
    )->save;
    assert_right(
        code        => 'foo',
        test        => 'D and referents get simple right, generation conflict resolution',
        role_map    => $role_map,
        roles       => [qw( A !B !C D !E F )],
    );

    diag("Group Eight");
    assert_right(
        code        => 'foo',
        roles       => [qw( !A !B !C !D !E !F )],
        role_map    => $role_map,
        test        => 'No rights to other roles as default',
        target      => $role_map->{A},
    );
    assert_target_set(
        code        => 'foo',
        test        => 'Single target lookup with multiple-targets syntax',
        role_map    => $role_map,
        target_map  => $role_map,
        targets     => 'A',
        assertions  => {
            A   => '',
            B   => '',
            C   => '',
            D   => '',
            E   => '',
            F   => '',
        },
    );

    diag("Group Nine");
    my $right = $right_class->new(
        db            => $db,
        right_type_id => $right_type_role->id,
        role_id       => $role_map->{B}->id,
        is_granted    => 't',
    )->save;
    $right_target_class->new(
        db         => $db,
        right_id   => $right->id,
        ref_obj_pk => $role_map->{A}->id,
    )->save;
    assert_right(
        code        => 'foo',
        roles       => [qw( !A B !C D !E F )],
        role_map    => $role_map,
        test        => 'Role visibility basic',
        target      => $role_map->{A},
    );
    assert_right(
        code        => 'foo',
        roles       => [qw( !A B !C D !E F )],
        target      => $role_map->{F},
        test        => 'Role visibility with target inheritance',
        role_map    => $role_map,
    );
    assert_target_set(
        code        => 'foo',
        test        => 'Multiple target lookup with B given rights to A',
        role_map    => $role_map,
        target_map  => $role_map,
        targets     => 'A F',
        assertions  => {
            A   => '',
            B   => 'A F',
            C   => '',
            D   => 'A F',
            E   => '',
            F   => 'A F',
        },
    );

    diag("Group Ten");
    $right = $right_class->new(
        db          => $db,
        is_granted  => 'f',
        right_type_id   => $right_type_role->id,
        role_id     => $role_map->{B}->id,
    )->save;
    $right_target_class->new(
        db          => $db,
        right_id    => $right->id,
        ref_obj_pk  => $role_map->{C}->id,
    )-> save;
    assert_right(
        target  => $role_map->{C},
        roles   => [qw( !A !B !C !D !E !F )],
        code    => 'foo',
        role_map    => $role_map,
        test        => 'Explicit deny to role',
    );
    assert_right(
        target      => $role_map->{D},
        code        => 'foo',
        role_map    => $role_map,
        roles       => [qw( !A B !C D !E F )],
        test        => 'Explicit deny with target inheritance'
    );
    assert_target_set(
        code        => 'foo',
        test        => 'Multiple target lookup with explicit denial',
        role_map    => $role_map,
        target_map  => $role_map,
        targets     => 'C D',
        assertions  => {
            A   => '',
            B   => 'D',
            C   => '',
            D   => 'D',
            E   => '',
            F   => 'D',
        },
    );

    diag("Group Eleven");
    $right = $right_class->new(
        db          => $db,
        right_type_id   => $right_type_role->id,
        role_id     => $role_map->{B}->id,
        is_granted    => 't',
    )->load( speculative => 1)->save;
    $right_target_class->new(
        db          => $db,
        right_id    => $right->id,
        ref_obj_pk  => $role_map->{E}->id,
    )->save;
    assert_right(
        roles       => [qw( !A B !C D !E F )],
        target      => $role_map->{E},
        code        => 'foo',
        role_map    => $role_map,
        test        => 'Allow/deny inheritance resolution',
    );
    assert_target_set(
        code        => 'foo',
        test        => 'Multiple target lookup for allow/deny inheritance resolution',
        role_map    => $role_map,
        target_map  => $role_map,
        targets     => 'A B C D E F',
        assertions  => {
            A   => '',
            B   => 'A D E F',
            C   => '',
            D   => 'A D E F',
            E   => '',
            F   => 'A D E F',
        },
    );

    diag("Group Twelve");
    $right = $right_class->new(
        db          => $db,
        role_id     => $role_map->{D}->id,
        right_type_id   => $right_type_role->id,
        is_granted    => 't',
    )->save;
    $right_target_class->new(
        db         => $db,
        ref_obj_pk => $role_map->{C}->id,
        right_id   => $right->id,
    )->save;
    assert_right(
        db      => $db,
        roles   => [qw( !A B !C D !E F )],
        target  => $role_map->{D},
        role_map    => $role_map,
        code    => 'foo',
        test    => 'Further allow/deny inheritance resolution',
    );
    assert_right(
        db      => $db,
        roles   => [qw( !A !B !C D !E F )],
        target  => $role_map->{C},
        role_map    => $role_map,
        code        => 'foo',
        test        => 'Still further allow/deny inheritance resolution',
    );
    assert_target_set(
        code        => 'foo',
        test        => 'Full target lookup for further allow/deny inheritance resolution',
        role_map    => $role_map,
        target_map  => $role_map,
        targets     => 'A B C D E F',
        assertions  => {
            A   => '',
            B   => 'A D E F',
            C   => '',
            D   => 'A C D E F',
            E   => '',
            F   => 'A C D E F',
        },
    );

    diag("Group Thirteen: Site Mgmt Funcs");

    $site_mgmt_funcs = test_site_mgmt_funcs($db);
    $right = $right_class->new(
        db            => $db,
        right_type_id => $right_type_site_mgmt_func->id,
        role_id       => $role_map->{C}->id,
        is_granted    => 't',
    )->save;
    $right_target_class->new(
        db         => $db,
        right_id   => $right->id,
        ref_obj_pk => $site_mgmt_funcs->{Test_1}->code,
    )->save;
    assert_right(
        code     => 'foo',
        test     => 'Simple right with target check',
        role_map => $role_map,
        roles    => [qw( !A !B C !D E F )],
        target   => $site_mgmt_funcs->{Test_1},
    );
    assert_target_set(
        code       => 'foo',
        test       => 'Target checks',
        role_map   => $role_map,
        target_map => $site_mgmt_funcs,
        targets    => 'Test_1 Test_2',
        assertions => {
            A => '',
            B => '',
            C => 'Test_1',
            D => '',
            E => 'Test_1',
            F => 'Test_1',
        },
    );
}; # eval for lack of transaction safety.

# clean up
diag('Cleaning up test data');
my $section = ${ [values %$site_mgmt_funcs] }[0]->section;
for my $killer (
    values(%$site_mgmt_funcs),
    values(%$role_map),
    $right_type_simple,
    $right_type_role,
    $right_type_site_mgmt_func,
    $section,
) {
    eval { $killer->delete };
    diag("Problem deleting %s: %s\n", ref($killer), $@) if $@;
}

#
# helper subs
#
sub has_relationship {
    my ($map, $relationship, $test_name) = @_;
    my ($negate, $source, $target, $generations) = (
        $relationship =~ /^(!?)([A-Z])([A-Z])(\d+)?$/
    );

    return fail("$test_name: role $source does not exist.")
        unless $source and $source = $map->{$source};

    return fail("$test_name: role $target does not exist.")
        unless $target and $target = $map->{$target};

    my $generation_set;
    use Data::Dumper ();
    eval {
        $generation_set = $source->has_role( $target, $generations );
        $generation_set = { map { $_ => $_ } @$generation_set }
            if $generations and $generation_set;
    };
    return fail("$test_name ERROR: $@") if $@;

    my $result = ($generation_set and !$generations || $generation_set->{$generations});
    $result = !$result if $negate;

    return ok( $result, $test_name );
}

sub assert_right {
    my (%opt) = @_;
    my $roles = delete $opt{roles};
    my $test = delete $opt{test};
    my @args = (delete $opt{code});
    push @args, delete $opt{target} if $opt{target};
    my $role_map = delete $opt{role_map};
    my @results;
    for my $role (@$roles) {
        my ($not, $key) = $role =~ /(!?)([A-Z])/;
        my $result = eval { $role_map->{$key}->check_right( @args); };
        my $output;
        if ($@) {
            diag("$test $key error --> $@");
            $output = $key . '-error';
        }
        else {
            $output = sprintf('%s%s', ($result ? '' : '!'), $key);
        }
        push @results, $output;
    }
    is(
        join(' ', @results),
        join(' ', @$roles),
        $test
    ) and return 1;
    #debug_dump_roles($role_map);
}

sub assert_target_set {
    my %opt = @_;
    my $assertions = delete $opt{assertions};
    die "Nothing to test!\n" unless keys %$assertions;
    
    my $test = delete $opt{test};
    my @args = (delete $opt{code});
    my $role_map = delete $opt{role_map};
    my $target_map = delete $opt{target_map};

    my $targets = [ map { $target_map->{$_} } split / /, delete $opt{targets} ];

    push @args, $targets;

    my $reverse_target = {
        map { $target_map->{$_}->as_hashkey => $_ } keys %$target_map
    };
    
    my %results;

    for my $role (keys %$assertions) {
        my $result = eval { $role_map->{$role}->check_right( @args ) } || '';
        if ($@) {
            diag("$test $role error --> $@");
            $results{$role} = $role . '-error';
            next;
        }
        $result = join ' ', sort { $a cmp $b } map { $reverse_target->{ $_->as_hashkey } } @$result
            if $result;
        $results{$role} = $result;
    }

    my $result = is_deeply(
        \%results,
        $assertions,
        $test
    );

    #debug_dump_roles($role_map) unless $result;
    return $result;
}

sub test_roles {
    my $db = shift;
    if (! $db) {
        $db = IC::Model::Rose::Object->init_db;
        $db->dbh->begin_work;
    }
    
    my %role = map { $_ => $role_class->new( db => $db, code => $_, display_label => $_ )->save; } qw(
        A B C D E F
    );

    for my $rel (
        [qw( C A )],
        [qw( E C )],
        [qw( F E )],
        [qw( D A )],
        [qw( D B )],
        [qw( F D )],
    ) {
        $has_role_class->new(
            db          => $db,
            role_id     => $role{$rel->[0]}->id,
            has_role_id => $role{$rel->[1]}->id,
        )->save;
    }

    return \%role;
}

sub test_site_mgmt_funcs {
    my $db = shift;
    if (! $db) {
        $db = IC::Model::Rose::Object->init_db;
        $db->dbh->begin_work;
    }
    eval {
        my $section = IC::M::ManageFunction::Section->new(
            db            => $db,
            code          => 'test',
            status        => 1,
            display_label => 'Test',
        );
        $section->save;
    };
    if ($@) {
        warn "Died trying to instantiate section: $@\n";
    }

    my @funcs = map {
        my $new = $site_mgmt_func_class->new(
            db            => $db,
            code          => "Test_$_",
            display_label => "Test: $_",
            section_code  => 'test',
        );
        $new->save;
    } (1..5);

    return {
        map { $_->code => $_ } @funcs
    };
}

sub debug_dump_roles {
    my $map = shift;
    printf STDERR "==== ROLE DUMP:\n\t%s\n====\n", join("\n\t", map {"$_: " . $map->{$_}->id} sort keys %$map);
    return;
}

