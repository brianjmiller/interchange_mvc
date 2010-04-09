package IC::Routes::User;

use strict;
use warnings;

use IC::C::User;

use base qw( IC::Controller::Route );

IC::Controller::Route->route(
    pattern    => 'user/login',
    method     => 'get',
    controller => 'user',
    action     => 'login_form',
);
IC::Controller::Route->route(
    pattern    => 'user/login',
    method     => 'post',
    controller => 'user',
    action     => 'login_auth',
);
IC::Controller::Route->route(
    pattern     => 'user/switch',
    controller  => 'user',
    action      => 'switch_user',
);
IC::Controller::Route->route(
    pattern    => 'user/menu',
    method     => 'get',
    controller => 'user',
    action     => 'menu',
);
IC::Controller::Route->route(
    pattern    => 'user/logout',
    method     => 'get',
    controller => 'user',
    action     => 'logout',
);

IC::Controller::Route->route(
    pattern    => 'user/account_maintenance',
    method     => 'get',
    controller => 'user',
    action     => 'account_maintenance_form',
);
IC::Controller::Route->route(
    pattern    => 'user/account_maintenance',
    method     => 'post',
    controller => 'user',
    action     => 'account_maintenance_save',
);

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
