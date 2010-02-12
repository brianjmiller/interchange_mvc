package IC::Routes::Manage;

use strict;
use warnings;

use IC::C::Manage;

use base qw( IC::Controller::Route );

IC::Controller::Route->route(
    pattern     => 'manage/menu',
    controller  => 'manage',
    action      => 'menu',
);

IC::Controller::Route->route(
    pattern    => 'manage/function/:_function/:_step',
    controller => 'manage',
    action     => 'function',
    defaults   => {
        _step => 0,
    },
);

1;

__END__
