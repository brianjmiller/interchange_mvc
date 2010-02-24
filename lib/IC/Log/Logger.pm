package IC::Log::Logger;

use strict;
use warnings;

use IC::Log;

use vars qw/@EXPORT/;
use Exporter;
use base qw/Exporter/;

@EXPORT = qw/
	logger
	get_logger_default
/;

sub logger {
	my $self = shift;
    my $local_sub = $self->can('get_logger');
	my $logger = ($local_sub && $self->$local_sub()) || $self->get_logger_default;
	return $logger->can('log') ? $logger : $logger->logger;
}

sub get_logger_default {
	return 'IC::Log';
}

1;

__END__

=pod

=head1 NAME

IC::Log::Logger -- defines a general logging behavior for object modules

=head1 SYNOPSIS

B<IC::Log::Logger> exports methods that give a clean, manageable interface
for logging to arbitrary object modules.

Object modules making use of B<IC::Log::Logger> will receive a I<logger()>
method that will return a logging object (something derived from
B<IC::Log::Base>).  By default, the logger object returned will be the logger
object set in B<IC::Log>.  If the object module implements an attribute
accessor method named I<get_logger()>, the I<logger()> method will return the
logger object held in that attribute, falling back to the default logger if
the attribute is unset.

All object modules that import B<IC::Log::Logger> will get the same public
interface for logging, with the same underlying behavior; logging calls made
through the resulting I<logger()> method will go to a global default logging
object (in B<IC::Log>), but any object instance can set its own logger
attribute (in a manner idiomatic to that object's class), and I<logger()> will
ensure that the new logger is used for that object.  Furthermore, individual
classes can change the logger used by default as well via an override of
I<get_logger_default>.

In principle, B<IC::Log::Logger> gets imported into base classes, such that
all subclasses inherit the resulting logger interface, and a system ends up
having a consistent interface for logging through the entirety of its class
hierarchy.

=head1 USAGE

Suppose you have a new base class B<SuperKool::Widget> defining the interface
and behavior for a general "widget" object that happens to be really, really cool.
You want these widgets to be able to log stuff, and you want to use the same
logging interface that the rest of Interchange MVC uses (an entirely sensible desire).

We might start with this:

 package SuperKool::Widget;
 use IC::Log::Logger;
 use strict;
 use warnings;
 
 sub new {
     my $class = shift;
     my $obj = {};
     ... # some logic for initializing instances...
     bless $obj, $class;
     return $obj;
 }
 
 sub set_logger {
     my ($self, $logger) =  @_;
     die 'The logger specified is not a valid logger'
         if defined($logger)
         and !(
             $logger->can('log')
             || $logger->can('logger')
         )
     ;
     return $self->{_my_logger} = $logger;
 }
 
 sub get_logger {
     my $self = shift;
     return $self->{_my_logger};
 }
 ... # now implement the rest of this really, really cool widget.

So, we implemented get/set routines for a general logger attribute within our
SuperKool::Widget class, and named the get routine I<get_logger()> as this is
what B<IC::Log::Logger> expects for a read-only attribute accessor.

Within the methods of SuperKool::Widget that actually do stuff, including issuing
logging notifications, we can work with the logging interface thus:

 ... # assume $self is an instance of SuperKool::Widget
 $self->logger->debug('The value of $foo is: %d', $foo);

So, what actually does the I<debug()> call above?  It depends on the state of
I<$self>.  Assuming that the logger attribute has not been set on the instance
via I<set_logger()>, then I<logger()> will return the logger object associated
with B<IC::Log>.  However, if the object's logger attribute has been set, then
the value of that attribute will be used.

Operate on the assumption that SuperKool::Widget never messes with its instances'
logger attribute internally, and simply defaults to that attribute being unset,
and then consider:

 my $widget = SuperKool::Widget->new;
 # any logging calls issued by the widget will use the default of B<IC::Log>.
 $widget->do_stuff_that_logs();
 
 # now we set the logger attribute, and the same routine ends up using that logger
 # instead of the default.
 $widget->set_logger( IC::Log::AwesomeLogger->new );
 $widget->do_stuff_that_logs();

This whole thing really is pretty simple.  Follow the conventions described
and it's trivially straightforward.  You get a nice logger() method that is
guaranteed to return a meaningful logger whether or not your object instance has one.

= head1 CONVENTIONS

Assuming that you want the instances of your importing object class to be able to
set their own logger (for precise control), your importing object must:

=over

=item *

Provide an attribute reader by the name of I<get_logger()>, which should
return the value of the atttribute.  From the perspective of B<IC::Log::Logger>,
any value that supports I<log()> or I<logger()> is valid.  If the attribute value
returned doesn't support one of these things, an error will occur when your
object's I<logger()> method is invoked.

=back

Note that B<IC::Log::Logger> will do the right thing if your class doesn't implement
a I<get_logger()> method; in that case, calls to I<logger()> will always result in
use of the default logging choice.

The methods exported by B<IC::Log::Logger> include:

=over

=item *

I<logger()>

=item *

I<get_logger_default()>

=back

The I<get_logger_default()> results in the use of B<IC::Log> as the default logging
choice.  See below for details about overriding this to change the default logging choice
in a given class (and its derivatives).

=head2 LOGGER ATTRIBUTE WRITE ACCESSOR

While B<IC::Log::Logger> doesn't care how your classes go about setting an instance's
logger attribute (only caring that it can read that attribute via I<get_logger()>),
it is standard practice for the write accessor for the attribute to be named
I<set_logger()>, accepting the new value as the sole argument (beyond the invocant
itself, of course).  Furthermore, it is standard practice that I<set_logger()> be
able to unset the attribute if called with no argument or with an explicit I<undef>.

It is advisable to follow this common practice, as it maximizes consistency throughout
the system and therefore minimizes confusion for users of all modules in the system.

=head1 METHODS

The following methods are exported by B<IC::Log::Logger>:

=over

=item I<logger()>

The entire point of this whole exercise, I<logger()> will return something capable
of logging, looking first to the invocant's I<get_logger()> method to see if that
returns a meaningful value (and returning it if so), and falling back to using
the logging object associated with I<get_logger_default()> otherwise.

If the value used, be it from the object's attribute or from the default logging
choice, implements the I<log()> method, then the value is returned directly.  Otherwise,
I<logger()> is invoked on the value and the result of that is returned.  This allows
package names (like 'IC::Log') to function effectively in this scheme.

=item I<get_logger_default()>

The purpose of I<get_logger_default()> is to provide the fallback logging choice when
the invocant against which I<logger()> is called does not have a logging object set (or
does not implement the I<get_logger()> method at all).

I<get_logger_default()> returns 'IC::Log'.  This means that the default logging choice
for all consumers of B<IC::Log::Logger> is the B<IC::Log> package's logger.

Classes are free to override this with their own behavior, which would mean that a given
class would always fall back to some other logging choice.  The only requirement for
an implementation of I<get_logger_default()> is that the value returned implement either
the I<log()> or I<logger()> methods.  It is typically the case that a value that implements
I<log()> will be an instance of a B<IC::Log::Base> derivative, while a value implementing
I<logger()> will be the name of a package that is a derivative of B<IC::Log>.  It is
theoretically possible that an implementation of I<get_logger_default()> could return
a consumer of B<IC::Log::Logger>, and it might actually work okay, but it also could
end up in a never-ending loop, so don't do anything stupid.

Note that if you wish to override I<get_logger_default()> in a class that is actually
doing the initial import of B<IC::Log::Logger>, you'll receive a warning in doing
so (you do have warnings turned on, right?); in that case, you're probably best off
specifying that you only want to import "logger" in your "use IC::Log::Logger" call
within that module.  This is not a concern in subclasses of a base class when the base
class uses B<IC::Log::Logger>.

=back

=head1 SEE ALSO

=over

=item B<IC::Log::Base>

This defines the interface for any logging object.  You ultimately will need to know
that interface to work with whatever gets returned by I<logger()>.

=item B<IC::Log>

This provides a namespace for global logging objects, and serves as the default
logging mechanism for anything using B<IC::Log::Logger> (unless overridden).

=item B<IC::Log::Logger::Moose>

A specialized Moose class that uses B<IC::Log::Base> from which other Moose
classes may inherit to automatically get the logging interface discussed.

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
