package IC::Exceptions;

use strict;
use warnings;

use Exception::Class (
    'IC::Exception' => {
        description => 'Base IC Exception',
    },

    # Error Types
    'IC::Exception::InternalError' => {
        description => 'Unrecoverable Error',
        isa         => 'IC::Exception',
    },
    'IC::Exception::UserError' => {
        description => 'Recoverable Error (User)',
        isa         => 'IC::Exception',
    },
);

use IC::Exceptions::InternalErrors;
use IC::Exceptions::UserErrors;

1;

__END__
