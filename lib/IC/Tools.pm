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

=pod

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
