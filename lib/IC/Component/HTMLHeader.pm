package IC::Component::HTMLHeader;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

has 'page_title' => (
    is => 'rw',
);
has 'body_args' => (
    is => 'rw',
);

no Moose;

sub execute {
    my $self = shift;
    my $args = { @_ };

    my $context = {
        page_title  => $self->page_title,
        body_args   => $self->body_args,
        stylesheets => $self->controller->additional_stylesheets,
        js_libs     => $self->controller->additional_js_libs,
    };

    return $self->render(
        context => $context,
        view    => 'html_header',
    );
}

1;

__END__
