package IC::Component::HTMLFooter;

use strict;
use warnings;

use Moose;

extends 'IC::Component';

no Moose;

sub execute {
    my $self = shift;

    return $self->render(
        view => 'html_footer',
    );
}

1;

__END__
