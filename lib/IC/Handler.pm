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

        my $view_path
            = $::Variable->{MVC_VIEW_PATH}
                || $Global::Variable->{MVC_VIEW_PATH}
                || $Vend::Cfg->{VendRoot} . '/views'
        ;
        #::logDebug(
            #'mvc_dispatcher(): route class "%s" controller class "%s" view path "%s" URL "%s"',
            #$route_class,
            #$controller_class,
            #$view_path,
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
