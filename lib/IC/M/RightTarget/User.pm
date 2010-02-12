package IC::M::RightTarget::User;

use strict;
use warnings;

sub implements_type_target {
    return 'user';
}

#sub target_relationship { 
    #return 'user_targets';
#}

sub target_influencers {
    my $self = shift;
    my $targets = shift;

    my $return;
    for my $target (@$targets) {
        $return->{$target->id} = [
            [ $target->id ],
        ];
    }

    return $return;
}

1;

__END__
