package IC::Component::OptionList::Months;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

has 'current' => (
    is => 'rw',
    default => sub {
        (localtime)[4] + 1
    },
);
has 'selected' => (
    is      => 'rw',
);

no Moose;

my $months = [
    {
        numerical   => '1',
        name        => 'January',
        abbr_name   => 'Jan',
        num_of_days => '31',
    },
    {
        numerical   => '2',
        name        => 'February',
        abbr_name   => 'Feb',
        num_of_days => '29',
    },
    {
        numerical   => '3',
        name        => 'March',
        abbr_name   => 'Mar',
        num_of_days => '31',
    },
    {
        numerical   => '4',
        name        => 'April',
        abbr_name   => 'Apr',
        num_of_days => '30',
    },
    {
        numerical   => '5',
        name        => 'May',
        abbr_name   => 'May',
        num_of_days => '31',
    },
    {
        numerical   => '6',
        name        => 'June',
        abbr_name   => 'Jun',
        num_of_days => '30',
    },
    {
        numerical   => '7',
        name        => 'July',
        abbr_name   => 'Jul',
        num_of_days => '31',
    },
    {
        numerical   => '8',
        name        => 'August',
        abbr_name   => 'Aug',
        num_of_days => '31',
    },
    {
        numerical   => '9',
        name        => 'September',
        abbr_name   => 'Sept',
        num_of_days => '30',
    },
    {
        numerical   => '10',
        name        => 'October',
        abbr_name   => 'Oct',
        num_of_days => '31',
    },
    {
        numerical   => '11',
        name        => 'November',
        abbr_name   => 'Nov',
        num_of_days => '30',
    },
    {
        numerical   => '12',
        name        => 'December',
        abbr_name   => 'Dec',
        num_of_days => '31',
    },
];

sub execute {
    my $self = shift;
    my $args = { @_ };

    my @options;
    for my $month (@$months) {
        my $selected = 0;
        if (defined $self->selected and $self->selected ne '') {
            if ($self->selected eq '_current') {
                if ($month->{numerical} == $self->current) {
                    $selected = 1;
                }
            }
            elsif ($self->selected == $month->{numerical}) {
                $selected = 1;
            }
        }

        push @options, {
            value    => sprintf('%02d', $month->{numerical}),
            label    => $month->{name},
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
