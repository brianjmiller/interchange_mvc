package IC::Controller::RenderHelper;

use strict;
use warnings;

use Exporter;
use IC::Controller::HelperBase;

use base qw(Exporter IC::Controller::HelperBase);

@IC::Controller::RenderHelper::EXPORT = qw(
    render
);

sub render {
    # aargh, cap'n, methinks we be needin' an exception object here!
    my $controller = __PACKAGE__->controller;
    die 'cannot render() without a current controller!'
        unless $controller
    ;
    
    my %options = @_;
    # only permit view and context
    delete @options{grep !/^(?:view|context)$/, keys %options};
    $options{layout} = undef;
    return $controller->render_local( %options );
}

1;

__END__
