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
);

use IC::Exceptions::InternalErrors::Controller;
use IC::Exceptions::InternalErrors::Response;

1;

__END__
