package IC::Log::Logger::Moose;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use IC::Log::Logger;

type ICLogger =>
	where {
		UNIVERSAL::can($_, 'log')
		||
		UNIVERSAL::can($_, 'logger')
	};

has logger => (
	reader =>		'get_logger',
	writer =>		'set_logger',
	predicate =>	'has_logger',
	isa =>			'Maybe[ICLogger]',
);

1;

__END__

=pod

=head1 NAME

IC::Log::Logger::Moose -- a Moose base class for objects in need of logging

=head1 SYNOPSIS

Moose is the standard object system for Interchange MVC.  Since it is not uncommon
that a given object class would use Moose, and would also want to have the logging
interface outlined by B<IC::Log::Logger>, the B<IC::Log::Logger::Moose> class
defines a basic Moose object class that works with B<IC::Log::Logger>, such that
any class built with Moose in need of that kind of logging capability may simply
derive from B<IC::Log::Logger::Moose>.

=head1 USAGE

Any object of this class or of a derivative thereof could be used in the
following manner:

 # An instance of this class does very little, but illustrates the point
 my $obj = IC::Log::Logger::Moose->new;
 
 # Use the system default logger of IC::Log...
 $obj->logger->warn('Oh, no, a logging message!');
 
 # Use a specific logger object instead of system default.
 $obj->set_logger( IC::Logger::SuperDuperLogMechanism->new );
 $obj->logger->warn('Oh, my, this one goes to the super-duper logs');

It would be fairly unusual for consumers of a given object class to make use
of that object class' logging facility; more likely is that the consumer of the class
specifies the kind of logging used by ta particular instance, and that instance issues
its own logging calls appropriately.

=head2 SUBCLASSES

The most common use scenario for B<IC::Log::Logger::Moose> would be in subclassing.

 package I::Have::Logger::Behavior;
 use Moose;
 use IC::Log::Logger::Moose;
 extends 'IC::Log::Logger::Moose';
 
 has some_attribute => (is => 'rw', default => sub { 'foo' });
 
 sub some_method {
     my $self = shift;
     $self->logger->notice(
         'object of class %s has some_attribute value: %s',
         ref($self),
         $self->some_attribute,
     );
 }

An instance of the example I::Have::Logger::Behavior class would issue notifications
via what logger happens to be appropriate for that instance.  It would inherit the
appropriate attribute and accessor methods from B<IC::Log::Logger::Moose>.

This basically means that you can create new class hierarchies that have this kind of
logging setup without having to think about it.  Just inherit from this class and go.

=head1 ATTRIBUTES

=over

=item I<get_logger()>, I<set_logger()>, I<has_logger()>

An abstract "logger" attribute is provided that is accessed with the get/set/has methods
listed.  This breaks from Interchange MVC's usual reliance on Moose 'rw' attribute methods
in which a single method performs both read and write operations to the attribute.

Use I<set_logger()> to specify a particular logging construct to use (either an object
derived from B<IC::Log::Base> or the name of a package derived from B<IC::Log>) for
a given instance.  The logging construct set will then be used by any call to the I<logger()>
method.

A type constraint is placed on this attribute, such that attempting to set it with
a value that does not support the I<log()> or I<logger()> methods will throw an exception.

The attribute is unset by default, meaning that I<logger()> will use the default logging
choice.

Note: I<has_logger()> returns whether the attribute has been specifically set, not whether
it has a value/is defined.

=back

=head1 METHODS

The following methods are provided by B<IC::Log::Logger::Moose> by virtue of it
pulling them in from B<IC::Log::Logger>.  Please refer to B<IC::Log::Logger> for
more details.

=over

=item I<logger()>

Returns the appropriate logging object based on the invocant's state and the default
logging choice.

You could certainly override this in subclasses if desired, though the value of such
an act is unclear.

=item I<get_logger_default()>

Determines the default logging choice; returns 'IC::Log' by default.  This can be
overridden in your subclasses as appropriate.

=back

=head1 SEE ALSO

=over

=item B<IC::Log::Base>

Anything returned by I<logger()> will be a derivative of B<IC::Log::Base>.

=item B<IC::Log::Logger>

The module that defines this general "I'm an object with logging support" behavior.

=item B<IC::Log>

The system default logging object namespace.

=back

=head1 CREDITS

Authors: Mark Johnson (mark@endpoint.com); Ethan Rowe (ethan@endpoint.com)

=cut
