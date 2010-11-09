package IC::Manage::Files::Properties;

use strict;
use warnings;

use IC::M::File::Property;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::Manage';

class_has '+_class'                     => ( default => 'Files__Properties' );
class_has '+_model_class'               => ( default => __PACKAGE__->_root_model_class().'::File::Property' );
class_has '+_model_class_mgr'           => ( default => __PACKAGE__->_root_model_class().'::File::Property::Manager' );
class_has '+_model_display_name'        => ( default => 'File Property' );
class_has '+_model_display_name_plural' => ( default => 'File Properties' );

no Moose;
no MooseX::ClassAttribute;

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
