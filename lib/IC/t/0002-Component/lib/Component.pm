package Component;

use strict;
use warnings;

use IC::Component ();
use base qw(IC::Component);
use Moose;

__PACKAGE__->register_bindings(qw(
    a
    b
    c
));

sub execute {
    my ($self, %params) = @_;
    return $self->render( %params );
}

sub base_view_regex {
    my $self = shift;
    my @terms;
    push @terms, 'controller=' . $self->controller->registered_name;
    push @terms, map { my $sub = $self->can($_); $_ . '=' . $self->url( binding => $self->$sub() ) } qw(
        a
        b
        c
        binding
    );
    my $pattern = join '\\s+', @terms;
    return qr{(?:^|\s+)$pattern(?:\s+|$)};
}

1;
