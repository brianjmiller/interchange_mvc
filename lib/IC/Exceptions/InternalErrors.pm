package IC::Exceptions::InternalErrors;

use strict;
use warnings;

use Exception::Class (
    'IC::Exception::UnknownMethod' => {
        description => 'System: Unknown Method',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::UndefinedObject' => {
        description => 'System: Undefined Object',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::FeatureNotImplemented' => {
        description => 'System: Feature Not Implemented',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::ArgumentMissing' => {
        description => 'System: Argument Missing',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::ObjectInitFailure' => {
        description => 'System: Object Init Failure',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::ModelLoadFailure' => {
        description => 'Model Load Failure',
        isa         => 'IC::Exception::InternalError',
    },
    'IC::Exception::ModelInstantiateFailure' => {
        description => 'Model Instantiation Failure',
        isa         => 'IC::Exception::InternalError',
    },
);

use IC::Exceptions::InternalErrors::Controller;
use IC::Exceptions::InternalErrors::Response;

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
