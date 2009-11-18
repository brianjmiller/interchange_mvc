package TestRoutes;

use strict;
use warnings;

use IC::Controller::Route;

use base qw(IC::Controller::Route);

__PACKAGE__->route(
    pattern => 'bad',
    controller => 'some nonexistant controller name',
    defaults => {
        action => 'error_action',
    },
);
__PACKAGE__->route(
    pattern => '*foo',
    controller => 'app_with_ref',
    defaults => {
        action => 'error_action',
    },
);

1;

__END__
