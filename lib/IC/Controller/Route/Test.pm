package IC::Controller::Route::Test;

use strict;
use warnings;

use IC::Controller::Route;

use base qw/IC::Controller::Route/;

use URI::Escape qw/uri_escape_utf8 uri_unescape/;
use Data::Dumper qw/Dumper/;

sub generate_path {
    my ($self, %opt) = @_;
    %opt = %{ $self->params_to_path(\%opt) };
    return $self->SUPER::generate_path(%opt);
}

sub parse_path {
    my ($self, @args) = @_;
    return $self->params_from_path( $self->SUPER::parse_path(@args) );
}

sub params_to_path {
    my ($self, $params) = @_;
    $params ||= {};
    my $copy = {};
    %$copy = %$params;
    delete @$copy{qw/action controller/};
    delete @$params{keys %$copy};
    $params->{parameters} = uri_escape_utf8(Dumper($copy));
    return $params;
}

sub params_from_path {
    my ($self, $params) = @_;
    return unless defined $params;
    my $stream = uri_unescape(delete($params->{parameters}) || '');
    my $embedded_params = eval $stream;
    die "Parameters fail to convert to a hash!\n"
        unless ref($embedded_params) eq 'HASH'
    ;
    $params->{$_} = $embedded_params->{$_}
        for grep !exists($params->{$_}), keys(%$embedded_params)
    ;
    return $params;
}

__PACKAGE__->route(
    pattern     => ':controller/:action/:parameters',
    defaults    => {
        parameters => '{}',
    },
);

1;

__END__

=pod

=head1 NAME

IC::Controller::Route::Test -- a helper module for testing controllers/routes

=head1 SYNOPSIS

In order to test the operations of a given controller, you really need a supporting
route module that will do the path processing you expect in your test.  For a test
to be rigorous, we don't want to have to tie the controller's functionality to a
given route; they're separate pieces of functionality.

Therefore, B<IC::Controller::Route::Test> is provided to give a very generic
routing behavior on which controller tests can rely.  It has been designed such
that any controller/action combination, along with any other arbitrary parameters
you provide the path functions, can generate a decent (ugly) path that can in
turn be parsed in order to reconstruct said arbitrary parameters/action/controller.

=head1 USAGE

You wouldn't really use B<IC::Controller::Route::Test> directly; intead,
the B<IC::Controller::Test> helper module uses it for you to ensure that
url generation will work, and that things like redirect() can be reliably
tested to ensure that the redirection target path expresses the parameters
required, etc.

If you must know, it's a subclass of B<IC::Controller::Route>, and can be
used as such.  It provides its own single route, and overrides the
I<generate_path()> and I<parse_path()> methods so that it converts any
parameters you provide (other than I<controller> and I<action>) into
a URI-escaped serialized data stream that can be treated as a URI path parameter
by the routing system (and, in the case of I<parse_path()>, knows to convert
back from this stream into the original data structure).

Therefore, it really ought to be able to handle any set of parameters so long
as they are serializable by Data::Dumper.

=head1 CREDITS

Original author: Ethan Rowe (ethan@endpoint.com)

