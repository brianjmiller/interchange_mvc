package IC::Exceptions::UserErrors::Controller;

use strict;
use warnings;

use Exception::Class (
    'IC::Exception::LoginRequired' => {
        description => 'Controller: Login Required',
        isa         => 'IC::Exception::UserError',
    },
);

1;

__END__
