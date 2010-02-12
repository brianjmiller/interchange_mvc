package IC::M::RightTarget::Role;

use strict;
use warnings;

sub implements_type_target {
    return 'role'
}

#sub target_relationship {
    #return 'role_targets';
#}

sub target_influencers {
    my $self = shift;
    my $targets = shift;
    my $graph = shift;

    return {
        map { $_->as_hashkey => $graph->references($_->id) } @$targets
    };
}

1;

__END__
