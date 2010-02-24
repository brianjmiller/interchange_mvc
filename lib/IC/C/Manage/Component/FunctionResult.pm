package IC::C::Manage::Component::FunctionResult;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;

extends 'IC::Component';

class_has '_kind' => ( is => 'ro', default => undef );

has 'view' => (
    is      => 'ro',
    default => undef,
);
has 'context' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

no Moose;

sub execute {
    my $self = shift;
    my $ctl  = $self->controller;

    $ctl->add_stylesheet(
        kind => 'ic',
        path => 'components/manage/function/' . $self->_kind . '.css',
    );

    return $self->render(
        context => $self->context,
        view    => $self->view,
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
