package IC::Tools;

use strict;
use warnings;

#
# Vend::Util::round_to_frac_digits is used by the round() method
# but could be inlined directly if necessary (with minor modifications)
#
use Vend::Util;
use DateTime;
use Time::HiRes qw();

sub round {
    my $self = shift;
    my $amount = shift;

    return 0 unless defined $amount;

    my $return = Vend::Util::round_to_frac_digits($amount, 2);
    return $return;
}

sub current_date {
    DateTime->today;
}

sub current_timestamp {
    DateTime->now;
}

1;

__END__
