package IC::C::Manage::Component::FunctionResult::ListPaginated;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::C::Manage::Component::FunctionResult';

class_has '+_kind' => ( default => 'list_paginated' );
has '+view'        => ( default => 'manage/function/list_paginated' );

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
