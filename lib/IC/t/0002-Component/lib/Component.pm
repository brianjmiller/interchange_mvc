package Component;

use strict;
use warnings;

use IC::Component ();
use base qw(IC::Component);
use Moose;

__PACKAGE__->register_bindings(qw(
    a
    b
    c
));

sub execute {
    my ($self, %params) = @_;
    return $self->render( %params );
}

sub base_view_regex {
    my $self = shift;
    my @terms;
    push @terms, 'controller=' . $self->controller->registered_name;
    push @terms, map { my $sub = $self->can($_); $_ . '=' . $self->url( binding => $self->$sub() ) } qw(
        a
        b
        c
        binding
    );
    my $pattern = join '\\s+', @terms;
    return qr{(?:^|\s+)$pattern(?:\s+|$)};
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
