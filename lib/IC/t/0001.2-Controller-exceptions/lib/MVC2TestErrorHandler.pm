package MVC2TestErrorHandler;

use strict;
use warnings;

use Scalar::Util qw(blessed);

sub my_handler {
    my ($self, $err) = @_;
    my $response = IC::Controller::Response->new;
    $response->buffer(
        'handled error from ' . (blessed($self) || $self)
    );
    return $response;
}

sub error_action {
    my $self = shift;
    die sprintf("error_action: %s\n", (blessed($self) ? blessed($self) . ' object' : $self));
}

1;

__END__
