package IC::Component::OptionList::Days;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

has 'current' => (
    is => 'rw',
    default => sub {
        (localtime)[3]
    },
);
has 'selected' => (
    is      => 'rw',
);

no Moose;

sub execute {
    my $self = shift;
    my $args = { @_ };

    my $num_days = 31;

    my @options;
    for my $day (1..$num_days) {
        my $selected = 0;
        if (defined $self->selected and $self->selected eq '_current') {
            if ($day == $self->current) {
                $selected = 1;
            }
        }
        elsif (defined $self->selected and $self->selected == $day) {
            $selected = 1;
        }
        push @options, {
            label    => $day,
            value    => sprintf('%02d', $day),
            selected => $selected,
        };
    }

    return $self->render(
        view => 'option_list',
        context => {
            options => \@options,
        },
    );
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
