package IC::M::Role::Walker;

use strict;
use warnings;

use Moose;

has roles => (is => 'rw', isa => 'ArrayRef', default => sub { [] });

has generations => (is => 'rw', isa => 'ArrayRef', default => sub { [] }, lazy => 1,);

has roles_inspected => (is => 'rw', isa => 'HashRef', default => sub { {} }, lazy => 1,);

has _next_set => (is => 'rw', isa => 'ArrayRef|Undef');

has _references_from => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    lazy    => 1,
);

has _references_to => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    lazy    => 1,
);

has _db => (is => 'rw');

no Moose;

sub next {
    my $self = shift;

    return $self->_next_generation(
        $self->_determine_next
    );
}

sub _determine_next {
    my $self = shift;
    
    my $generations = $self->generations;
    my $seen        = $self->roles_inspected;
    return [
        grep {
            !$seen->{ $_->id }
        }
        $self->current_generation
    ];
}

sub _next_generation {
    my $self = shift;
    my ($set) = @_;

    return unless @$set;

    my $generation = IC::M::Role->roles_referenced_by($set, $self->db);

    my $this_generation = {};
    my $ref_to          = $self->_references_to;
    my $ref_from        = $self->_references_from;
    my $history         = $self->roles_inspected;

    # the Perlist in me hates this, but it's fairly difficult
    # to maintain map statements that construct three separate lists.
    for my $role (@$generation) {
        my $id = $role->id;
        $this_generation->{ $id } = $role;

        for my $referent_role ( @{ $role->roles_using } ) {
            for ( [$referent_role, 0], values(%{ $ref_to->{ $referent_role->id } ||= {} }) ) {
                my $ref_id = $_->[0]->id;
                my $gen    = $_->[1] + 1;

                $ref_to->{ $id }{ $ref_id } ||= [$_->[0], $gen];
                $ref_from->{ $ref_id }{ $id } ||= [$role, $gen];
            }
        }
    }
    
    push @{$self->generations}, $this_generation;
    
    $self->add_inspected_roles( $set );

    return scalar(@$generation);
}

sub db {
    my $self = shift;

    my $db = $self->_db;
    if (! $db) {
        if (@{ $self->roles }) {
            $db = $self->roles->[0]->db;
        }
        else {
            $db = IC::M::Role->init_db;
        }
    }

    return $db;
}

sub add_inspected_roles {
    my $self = shift;
    my ($set) = @_;

    my $seen       = $self->roles_inspected;
    my $generation = @{ $self->generations };

    push(@{ $seen->{$_->id} ||= [] }, $generation)
        for @$set;

    return $seen;
}

sub current_generation {
    my $self = shift;

    my $gen = $self->generations;

    return @{ $self->roles } if ! @$gen;

    return values %{ $gen->[ $#$gen ] };
}

sub _references_hash_set {
    my $self = shift;
    my ($role, $hash, $with_generation) = @_;

    my $id = ref $role ? $role->id : $role;

    my @set = values %{ $hash->{$id} || {} };
    @set    = map { $_->[0] } @set unless $with_generation;

    return @set;
}

sub references_from {
    my $self = shift;
    my ($role, $with_generation) = @_;

    return $self->_references_hash_set( $role, $self->_references_from, $with_generation );
}

sub references_to {
    my $self = shift;
    my ($role, $with_generation) = @_;

    return $self->_references_hash_set( $role, $self->_references_to, $with_generation );
}

1;

__END__
