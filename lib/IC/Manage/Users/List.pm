package IC::Manage::Users::List;

use strict;
use warnings;

use Moose;
extends 'IC::Manage::Users';

augment 'ui_meta_struct' => sub {
    #warn "IC::Manage::Users::List::ui_meta_struct";
    my $self = shift;

    my $struct = $self->_ui_meta_struct;

    $struct->{+__PACKAGE__} = 1;

    my $inner_result = inner();

    return defined $inner_result ? $inner_result : $struct;
};

# TODO: my hunch is that a new Moose wouldn't require us to make these separate,
#       and really the second shouldn't be necessary at all
with 'IC::ManageRole::Base';
with 'IC::ManageRole::List';

has '+_paging_provider' => (
    default => 'server',
);

no Moose;

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
