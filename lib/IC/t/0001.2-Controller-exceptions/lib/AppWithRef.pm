package AppWithRef;

use strict;
use warnings;

use MVC2TestErrorHandler;

use base qw(IC::Controller MVC2TestErrorHandler);

__PACKAGE__->registered_name('app_with_ref');
__PACKAGE__->error_handler( \&MVC2TestErrorHandler::my_handler );

1;

__END__
