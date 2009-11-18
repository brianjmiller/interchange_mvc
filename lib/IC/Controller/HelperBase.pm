package IC::Controller::HelperBase;

use strict;
use warnings;

# This is so not thread-safe.  Oh well; neither is the rest of Interchange.
my $bound_controller;
sub bind_to_controller {
    # make this method non-inheritable (so to speak)
    my ($invocant, $controller) = @_;
    die 'bind_to_controller() may only be invoked from package ' . __PACKAGE__
        unless $invocant eq __PACKAGE__
    ;
    return $bound_controller = $controller;
}

sub controller {
    # This one, however, will be inheritable.
    return $bound_controller;
}

sub export_symbols {
    my $package = shift;
    my $export;
    for my $name (qw( EXPORT_OK EXPORT )) {
        my $var = "${package}::$name";
        my $exists;
        eval "\$exists = exists(\$${package}::{$name});";
        if ($exists) {
            no strict 'refs';
            $export = \@$var;
            last;
        }
    }
    return () unless defined $export;
    return map { /^[\$\@\%\&]/ ? $_ : '&' . $_ } @$export;
}

1;

__END__

=pod

=head1 NAME

IC::Controller::HelperBase -- the base module for all view "helpers"

=head1 DESCRIPTION

B<IC::Controller::HelperBase> provides a basic interface for building modules that can be
used within the context of your view templates.  In essence, each module is simply a glorified
exporter (see the B<Exporter> module for more), but modules may inherit from
B<IC::Controller::HelperBase> methods for accessing the current controller object and a
convenience method that normalizes the list of exported symbols to share with the view.

=head1 USAGE

This module would not typically be used directly; it is instead used as the base class for
any module the exported symbols of which you wish to make available to view languages.
Your module needs to be an exporter, and any of the symbols it exports will be made available
locally within the view (assuming the view language allows for this).  If your module needs
to know anything about the current request, the B<controller()> method can be called within
your module (as an OOP method-style call, not a standard function call) to have direct
access to the controller object and its attributes.

  package My::Helpers
  use Exporter;
  use IC::Controller::HelperBase;
  use base qw(Exporter IC::Controller::HelperBase);
  
  @My::Helpers::EXPORT = qw( get_happy );
  
  sub get_happy {
      return
          unless defined __PACKAGE__->controller
          and defined __PACKAGE__->controller->request;
          
      return 'happy!'
          if __PACKAGE__->controller->request->method eq 'get'
      ;
  
      return 'sad';
  }
  1;

The B<My::Helpers> module in the above example exports its 'get_happy' sub, which relies in turn
upon the B<controllers()> method inherited from B<IC::Controller::HelperBase>.  Thus, views
would have a B<get_happy()> sub available locally, the output of which being sensitive to the
current request.

B<BIG HINT>: the B<Exporter> man pages tell you not to export methods; the methods your module
inherits from B<IC::Controller::HelperBase> are indeed methods; that's not an accident.  Don't
export them.

=head1 METHODS

=over

=item B<bind_to_controller( $controller_instance )>

Binds B<IC::Controller::HelperBase> to the controller $controller_instance; this
controller object will subsequently be returned by calls to B<controller()>.

The B<bind_to_controller()> method will throw an exception if invoked against any package
other than B<IC::Controller::HelperBase>.

There's no need to use this method; the MVC subsystem uses it for you at the appropriate
times, so you should just leave it alone.

This is supremely thread-unsafe.  So is Interchange itself.  Pick your battles.

=item B<controller()>

Returns the current controller object bound to B<IC::Controller::HelperBase>.  Use this
within your helper modules to find out information about the current process, as shown
in the USAGE section above.

=item B<export_symbols()>

Inspects the invocant package's export-related array (@EXPORT_OK and @EXPORT, checked in that order)
to get the list of symbols exported by this module; normalizes the symbol list into a list
appropriate for passing to the B<share()> method of the B<Safe> module, so views that wrap
their goings-on in a Safe compartment can properly access the symbols of the package in question.

The MVC subsystem uses this method as it needs to when preparing view engines; there's no
reason to use it in your own code.

=back

=cut

