package IC::M::Graph::Cache;

use IC::M::Graph;

use Moose::Role;

with 'IC::M::Graph';
requires qw(
    build_cache
    clear_cache
    retrieve_cache
);

around initialize_map => sub {
    my ($continuation, $self) = @_;

    my $result = $self->retrieve_cache;
    unless (defined $result) {
        $result = $self->$continuation();
        $self->build_cache($result);
    }

    return $result;
};

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
