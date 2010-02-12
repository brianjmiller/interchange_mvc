package IC::C::Manage::Component::FunctionResult;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;

extends 'IC::Component';

class_has '_kind' => ( is => 'ro', default => undef );

has 'view' => (
    is      => 'ro',
    default => undef,
);
has 'context' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

no Moose;

sub execute {
    my $self = shift;
    my $ctl  = $self->controller;

    $ctl->add_stylesheet(
        kind => 'controlled',
        path => '_components/manage/function/' . $self->_kind . '.css',
    );

    return $self->render(
        context => $self->context,
        view    => $self->view,
    );
}

1;

__END__
