package IC::Log::Interchange;

use strict;
use warnings;

use IC::Log::Base;
use Moose;
extends qw/IC::Log::Base/;

has quiet_fallback => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 },
);

sub _log {
	my ($self, $level, $msg) = @_;

	$self->priority($level) < $self->priority('notice')
		? $self->_log_error($level, $msg)
		: $self->_log_debug($level, $msg)
	;

	return 1;
}

sub _log_dispatch {
    my ($self, $level, $msg, $sub) = @_;
    return 1 if !$sub and $self->quiet_fallback;
    return $sub
        ? $sub->(uc($self->priority_name($level)) . ": $msg")
        : $self->_fallback_log($level, $msg)
    ;
}

sub _log_error {
	my ($self, $level, $msg) = @_;
	no warnings 'once';
	my $sub = *::logError{CODE};
    return $self->_log_dispatch($level, $msg, $sub);
}

sub _log_debug {
	my ($self, $level, $msg) = @_;
	no warnings 'once';
	my $sub = *::logDebug{CODE};
    return $self->_log_dispatch($level, $msg, $sub);
}

1;

__END__

=pod

=head1 NAME

IC::Log::Interchange -- IC::Log interface for standard Interchange logging

=head1 SYNOPSIS

B<IC::Log::Interchange> provides a IC::Log-family interface for use of the
standard Interchange logs.

When used within a running Interchange, calls to the B<log()> method go through
the default priority and formatting processes of B<IC::Log::Base>, but then
pass through to Interchange's B<::logError()> and B<::logDebug()> routines.

When used outside a running Interchange, the fallback logging of B<IC::Log::Base>
is used, meaning that messages go to STDERR.

The results is that the same logging interface works in both situations, which
facilities MVC development, unit testing, etc., without fear of logging calls breaking.

The name of the priority level used will appear capitalized as a prefix to the logging
message submitted in the standard Interchange logs (when used in a running Interchange).

=head1 PRIORITY-TO-FUNCTION MAPPINGS

Since Interchange offer two main logging routines, the various priority levels have
to map to these routines appropriately.

The following priorities map to B<::logError>:

=over

=item *

emerg

=item *

alert

=item *

crit

=item *

error

=item *

warning

=back

The following priorities map to B<::LogDebug>:

=over

=item *

notice

=item *

info

=item *

debug

=back

This means that within Interchange logs, there is no meaningful difference between these
logging levels, apart from the fact that the priority's name appears as a prefix to the
logging message.

=head1 USAGE

Usage of this is pretty straightforward.
 
 use IC::Log::Interchange;
 
 my $logger = IC::Log::Interchange->new;
 
 ...
 
 $logger->debug('Hey, the value of $plonka is: %s', $plonka);
 
 ...
 
 if ($death_to_thee) {
     $logger->crit('Death specified by value: %s', $death_to_thee);
     die;
 }
 
 # This message will go to standard IC logs if in running IC, but will be quiet outside IC
 $logger->quiet_fallback(1);
 $logger->notice('If you see this message, you must be running me in IC!');

There's not much to it.

=head1 ATTRIBUTES

In addition to the usual attributes inherited from B<IC::Log::Base>, this class
also has:

=over

=item B<quiet_fallback>

A boolean attribute, defaulting to false, that when true turns off logging to
STDERR when the standard Interchange logging tools are not available (due to using
the logging facility outside the context of a running Interchnage, for instance).

This can be handy if you're unit testing code that has logging output and you
don't want the logging output to make noise to your terminal during testing.

=back

=head1 SEE ALSO

=over

=item B<IC::Log::Base>

The standard interface for logging objects, this outlines details of the I<log()> method
and the priority levels.

=item B<IC::Log>

This defines a global namespace for a single logger object.  It is probably most likely
that use of a logging object will occur via B<IC::Log> rather than direct management
of logging object instances.

=back

=head1 CREDITS

Authors: Mark Johnson (mark@endpoint.com); Ethan Rowe (ethan@endpoint.com)

=cut
