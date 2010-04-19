package IC::M::Period;

use strict;
use warnings;

use DateTime;
use IC::Tools;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_periods',
    columns => [
        code          => { type => 'varchar', not_null => 1, primary_key => 1, length => 30 },

        __PACKAGE__->boilerplate_columns,

        display_label => { type => 'varchar', not_null => 1, length => 100 },
    ],
    unique_keys => [ 'display_label' ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->code || 'Unknown Period');
}

{
    #
    # calculators receive the date (as an object) on which to base calculation
    # and return the start and end dates for the range, these are called as
    # methods to facilitate easy addition of overridden variations and additions
    #
    my $builtin_calculators = {
        today       =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt = $date->clone;

            return ($dt, $dt);
        },
        yesterday   =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt = $date->clone->subtract(days => 1);

            return ($dt, $dt);
        },
        this_week   =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_s = $self->_determine_week_start($date);
            my $dt_e = $self->_determine_week_end($date);

            return ($dt_s, $dt_e);
        },
        last_week   =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_s = $self->_determine_week_start($date->clone->subtract( days => 7 ));
            my $dt_e = $self->_determine_week_end($dt_s);

            return ($dt_s, $dt_e);
        },
        this_month  =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_e = DateTime->new( year => $date->year, month => $date->month, day => 1 )->add( months => 1)->subtract( days => 1 );
            my $dt_s = DateTime->new( year => $date->year, month => $date->month, day => 1 );

            return ($dt_s, $dt_e);
        },
        last_month  =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_e = DateTime->new( year => $date->year, month => $date->month, day => 1 )->subtract( days => 1 );
            my $dt_s = DateTime->new( year => $dt_e->year, month => $dt_e->month, day => 1 );

            return ($dt_s, $dt_e);
        },
        this_year   =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_e = DateTime->new( year => $date->year, month => 12, day => 31 );
            my $dt_s = DateTime->new( year => $date->year, month => 1, day => 1 );

            return ($dt_s, $dt_e);
        },
        last_year   =>  sub {
            my $self = shift;
            my $date = shift;

            my $dt_e = DateTime->new( year => $date->year, month => 12, day => 31 )->subtract( years => 1);
            my $dt_s = DateTime->new( year => $date->year, month => 1, day => 1 )->subtract( years => 1);
            
            return ($dt_s, $dt_e);
        },
    };

    sub start_and_end {
        my $self = shift;
        my $args = { @_ };

        $args->{reference_date} ||= IC::Tools->current_date;

        my ($start, $end);
        if ($self->can( $self->code )) {
            my $method = $self->code;
            ($start, $end) = $self->$method($args->{reference_date});
        }
        elsif (exists $builtin_calculators->{ $self->code }) {
            my $function = $builtin_calculators->{ $self->code };
            ($start, $end) = $self->$function($args->{reference_date});
        }
        else {
            IC::Exception->throw(q{Can't calculate start and end for range: } . $self->code);
        }

        return wantarray ? ($start, $end) : [ $start, $end ];
    }
}

sub _determine_week_start {
    my $self = shift;
    my ($datetime) = @_;

    # Monday is 1, Sunday is 7; we want to align things by Sunday
    my $days_adjust = $datetime->day_of_week % 7;
    my $sunday      = $datetime->clone;

    $sunday->subtract( days => $days_adjust ) if $days_adjust > 0;

    return $sunday;
}

sub _determine_week_end {
    my $self = shift;
    my ($datetime) = @_;

    # Monday is 1, Sunday is 7; we want to align things by Sunday
    my $days_adjust = 6 - $datetime->day_of_week % 7;
    my $saturday    = $datetime->clone;

    $saturday->add( days => $days_adjust ) if $days_adjust > 0;

    return $saturday;
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
