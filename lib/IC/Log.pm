package IC::Log;

use strict;
use warnings;

use Scalar::Util qw/blessed/;
use IC::Log::Interchange;

my %package_logger;

sub set_logger {
	my ($invocant, $logger) = @_;
	my $class = blessed($invocant) || $invocant;
	die 'The logger specified does not appear to be valid.'
		unless $logger->can('log');

	return $package_logger{$class} = $logger;
}

sub logger {
	my ($invocant, $logger) = @_;
	my $class = blessed($invocant) || $invocant;
	return $package_logger{$class} || $class->set_logger($logger);
}

__PACKAGE__->set_logger( IC::Log::Interchange->new );

1;

__END__

=pod

=head1 NAME

IC::Log -- interface to a global logging object

=head1 SYNOPSIS

Any application that utilizes logging for various purposes requires some kind
of mechanism for managing system-wide logging settings, and an interface to
the logging utility itself.

B<IC::Log> serves this purpose, acting as a namespace where the default logging
object (presumably a derivative of B<IC::Log::Base>) resides, and can be set
and accessed as needed throughout the application.

=head1 USAGE

It's really quite simple to make use of B<IC::Log>.

 package MyApp::Foo;
 use strict;
 use warnings;
 use IC::Log;

 sub do_stuff {
     IC::Log->logger->notice('I hath been called upon to do some stuff.');
     ... # now really do stuff...
 }

That's pretty much all there is to it, for most purposes.

If you want to change the global logging default, you can provide a new object
to the I<logger()> method, and subsequent I<logger()> calls will use the new
object.

 IC::Log->set_logger( MyApp::SpecialLogger->new );
 # now IC::Log->logger() returns the new instance of MyApp::SpecialLogger...
 IC::Log->logger->alert('This is an alert!  Fear me!');

Finally, if you wanted a similar kind of global logging construct but didn't want
to mess with the IC::Log one for whatever reason, you could subclass B<IC::Log>
and work with the subclass' I<logger()> method in the same manner, with no overlap
between the state of B<IC::Log> and your subclass:

 package MyApp::Logger;
 use strict;
 use warnings;
 use IC::Log;
 use base qw/IC::Log/;
 # set the logger appropriately
 __PACKAGE__->set_logger( MyApp::SpecialLogger->new );
 1;

Then, in some other bit of code:

 use MyApp::Logger;
 ...
 # this will log with the object we initially set in MyApp::Logger
 MyApp::Logger->logger->error('I am throwing an error for some reason');

Note that B<IC::Log> is no an object module; it does not create blessed instances
of itself.  It uses method invocation rather than subroutine imports/exports in
order to provide the inheritance capability demonstrated above.  The state of the
I<logger()> setting is bound to the package name against which I<logger()> is invoked,
so if you were to have an object module inherit from B<IC::Log>, calling I<logger()>
to set/get the logging object would still operate against the package name, not an object
instance.

If you want to build object modules that offer a logger interface, please see
B<IC::Log::Logger> and B<IC::Log::Logger::Moose>.

=head1 METHODS

=over

=item I<logger( $new_logger )>

Returns the logging object associated with the package name upon which the method is
invoked (usually B<IC::Log>, presumably).  If called with an argument, the argument
value is used as the new logging object for the package, if that package does not
already have a logger set; if the package already has a logger, then the argument is
ignored.

=item I<set_logger( $new_logger )>

Sets the logging object associated with the package name upon which method is invoked.
The I<$new_logger> will be validated to see if it can('log'); if this fails, an
exception is thrown.

=back

=head1 SEE ALSO

=over

=item B<IC::Log::Base>

The base class for logging objects in MVC Interchange.  It is basically assumed that the
values given to I<set_logger()> and returned by I<logger()> will be instances of this
class or its derivatives.

=item B<IC::Log::Interchange>

The default logging object class type used by B<IC::Log>.

=item B<IC::Log::Logger>

Defines a "has logging" behavior for object modules.

=back

=head1 CREDITS

Authors: Mark Johnson (mark@endpoint.com); Ethan Rowe (ethan@endpoint.com)

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
