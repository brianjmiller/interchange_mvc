package AppWithString;

use strict;
use warnings;

use MVC2TestErrorHandler;

use base qw(IC::Controller MVC2TestErrorHandler);

__PACKAGE__->registered_name('app_with_string');
__PACKAGE__->error_handler( 'my_handler' );

1;

__END__
