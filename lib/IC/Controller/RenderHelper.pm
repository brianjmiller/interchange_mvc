package IC::Controller::RenderHelper;

use strict;
use warnings;

use Exporter;
use IC::Controller::HelperBase;

use base qw(Exporter IC::Controller::HelperBase);

@IC::Controller::RenderHelper::EXPORT = qw(
    render
);

sub render {
    # aargh, cap'n, methinks we be needin' an exception object here!
    my $controller = __PACKAGE__->controller;
    die 'cannot render() without a current controller!'
        unless $controller
    ;
    
    my %options = @_;
    # only permit view and context
    delete @options{grep !/^(?:view|context)$/, keys %options};
    $options{layout} = undef;
    return $controller->render_local( %options );
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
