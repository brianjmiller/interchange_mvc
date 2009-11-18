package IC::Exceptions::UserErrors;

use strict;
use warnings;

use Exception::Class (
    'IC::Exception::MissingValue' => {
        description => 'User: Missing Value',
        isa         => 'IC::Exception::UserError',
    },
);

1;

__END__
