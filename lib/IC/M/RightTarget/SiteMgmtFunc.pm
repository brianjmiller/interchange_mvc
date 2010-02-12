package IC::M::RightTarget::SiteMgmtFunc;

use strict;
use warnings;

sub implements_type_target {
    return 'site_mgmt_func';
}

#sub target_relationship { 
    #return 'site_mgmt_func_targets';
#}

sub target_influencers {
    my $self = shift;
    my $targets = shift;

    my $return;
    for my $target (@$targets) {
        $return->{$target->code} = [
            [ $target->code ],
        ];
    }

    return $return;
}

1;

__END__
