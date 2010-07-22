package IC::Component::OptionList::Years;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

has 'current' => (
    is => 'rw',
    default => sub {
        (localtime)[5] + 1900
    },
);
has 'range_start' => (
    is => 'rw',
    default => sub {
        (localtime)[5] + 1900
    },
);
has 'range_end' => (
    is      => 'rw',
    default => sub {
        (localtime)[5] + 1900
    },
);
has 'lowest_to_highest' => (
    is      => 'rw',
    default => 0,
);
has 'selected' => (
    is      => 'rw',
);

no Moose;

sub execute {
    my $self = shift;
    my $args = { @_ };

    my @options;
    for my $year ($self->range_start..$self->range_end) {
        my $selected = 0;
        if (defined $self->selected and $self->selected ne '') {
            if ($self->selected eq '_current') {
                if ($year == $self->current) {
                    $selected = 1;
                }
            }
            elsif ($self->selected == $year) {
                $selected = 1;
            }
        }

        push @options, {
            label    => $year,
            value    => $year,
            selected => $selected,
        };
    }

    unless (defined $self->lowest_to_highest and $self->lowest_to_highest) {
        @options = reverse @options;
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
