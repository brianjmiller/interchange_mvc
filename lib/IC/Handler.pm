package IC::Handler;

use strict;
use warnings;

use IC::Exceptions;
use IC::Controller;
use IC::Controller::Response;

sub mvc_dispatcher {
    my $response;
    eval {
        my $route_class
            = $::Variable->{MVC_ROUTE_PACKAGE}
                || $Global::Variable->{MVC_ROUTE_PACKAGE}
                || 'IC::Controller::Route'
        ;

        my $controller_class
            = $::Variable->{MVC_CONTROLLER_PACKAGE}
                || $Global::Variable->{MVC_CONTROLLER_PACKAGE}
                || 'IC::Controller'
        ;

        #::logDebug(
            #'mvc_dispatcher(): route class "%s" controller class "%s" URL "%s"',
            #$route_class,
            #$controller_class,
            #$Vend::FinalPath,
        #);    

        $response = $controller_class->process_request(
            path            => $Vend::FinalPath,
            route_handler   => $route_class,
            cgi             => \%CGI::values,
            headers         => ::http()->{env},
            session         => $Vend::Session,
            values          => $::Values,
            scratch         => $::Scratch,    
        );
    };
    if ($@) {
        $response = IC::Controller::Response->new;
        $response->buffer($@);
        $response->headers->status('500 Internal Server Error');
    }

    return unless defined $response;

    $response->buffer( '' ) if ! defined $response->buffer;

    $Vend::StatusLine = $response->headers->headers;

    my $cookies_hashref = $response->headers->cookies;
    for my $name (keys %$cookies_hashref) {
        my $cookie = $cookies_hashref->{$name};
        Vend::Util::set_cookie($name, @{$cookie}{qw( value expire domain path )})
    }

    #::logDebug(
        #"mvc_dispatcher(): response structure received.\n\theaders: %s\n\tbody: \n%s",
        #$Vend::StatusLine,
        #${ $response->buffer }
    #);

    $Vend::tmp_session_allow_cookies = 1;
    ::response( $response->buffer );

    return;
}

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
