package IC::Component::HTMLHeader;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

has 'page_title' => (
    is => 'rw',
);
has 'body_args' => (
    is => 'rw',
);

no Moose;

sub execute {
    my $self = shift;
    my $args = { @_ };

    my $context = {
        page_title  => $self->page_title,
        body_args   => $self->body_args,
        stylesheets => $self->controller->additional_stylesheets,
        js_libs     => $self->controller->additional_js_libs,
    };

    return $self->render(
        context => $context,
        view    => 'html_header',
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
