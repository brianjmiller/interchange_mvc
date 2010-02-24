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
