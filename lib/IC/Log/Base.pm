package IC::Log::Base;

use strict;
use warnings;

use Moose;

=pod

=head1 NAME

IC::Log::Base -- base class for logging objects

=head1 SYNOPSIS

B<IC::Log::Base> defines basic behaviors and interface for logging
objects within the Interchange MVC implementation.  It is designed with
a sensible default behavior (dumping log information to STDERR), and
with subclassing in mind so subclasses of B<IC::Log::Base> can tie into
the logging system quite easily with minimal work.

=head1 USAGE

You wouldn't typically use B<IC::Log::Base> directly by itself.  The
most common use of it is via subclassing.  A subclass would be responsible
for overriding certain methods in order to implement meaningful logging
logic.

 package My::Logger;
 use IC::Log::Base;
 use base qw/IC::Log::Base/;
 use strict;
 use warnings;
 
 my $logfile = '/tmp/foo.log';
 open my $handle, '>', $logfile;
 
 sub _log {
     my ($self, $level, $message) = @_;
     print $handle, $message;
     return 1;
 } 
 
 1;

The above example opens up a file '/tmp/foo.log' and implements the I<_log()>
method to direct logging calls to that file.

The logging behavior of B<IC::Log::Base> includes an automatic formatting of
the message passed in.  However, it doesn't make any assumptions about line endings.
So, the above example would result in a messy logfile because we're not outputting
line endings per logging message.

We could elegantly fix this by introducing an additional overridden method:

 sub format_message {
     my $self = shift;
     my $msg = $self->SUPER::format_message( @_ );
     $msg .= "\n" unless $msg =~ /\n$/;
     return $msg;
 }

Now our My::Logger class continues to use the message formatting of B<IC::Log::Base>
but ensures that there's a trailing newline so the logfile looks better.

With this in place, we can use our logger in this manner:

 use My::Logger;
 
 my $logger = My::Logger->new;
 ...
 my $foo = 'blah';
 # send a debug message
 $logger->debug('The value of $foo is: %s', $foo);
  
 # send an error message
 $logger->error('$bar is undefined!') if !defined($bar);

The resulting entries in the '/tmp/foo.log' file would look like:

 The value of $foo is: blah
 $bar is undefined!
 

This reflects the default message formatting of the logging mechanism, which is
basically just I<sprintf> for whatever arguments are passed to the logging method.

Note that we used I<debug()> and I<error()> on our logger, but the resulting file
doesn't show any distinction for these.  This is because it's up to the logging
subclass itself to determine how the logging level is reflected in the resulting
logs, in whatever manner is most appropriate to the logging mechanism implemented.
If wrapping Syslog behind a B<IC::Log::Base> object, the logging levels could
basically pass right through to your syslog utility.  If doing some kind of file-based
logging, the logging level might determine which file a message goes to, or a prefix
on the message within a single file.  The base class makes no assumptions about this,
so it is entirely up to the subclass.

So what if our example subclass wanted to add a prefix appropriate to each logging
priority level?  Thenwe might do things like this:

 sub _log {
     my ($self, $level, $message) = @_;
     print $handle, uc($self->priority_name($level)) . ': ' . $message;
     return 1;
 }

The I<priority_name()> method would return the logging priority level name for
$level whether or not $level itself was a numeric value or in fact already a
level name.  So, with this implementation of I<_log()>, our example logfile would
instead look like:

 DEBUG: The value of $foo is: blah
 ERROR: $bar is undefined!
 

That's much clearer.

=head1 LOGGING PRIORITY LEVELS

B<IC::Log::Base> defines 8 different logging levels, equivalent to levels within
the syslog system:

=over

=item 0

emerg

=item 1

alert

=item 2

crit

=item 3

error

=item 4

warning

=item 5

notice

=item 6

info

=item 7

debug

=back

There is a method for each of these levels, but these methods are just a thin wrapper
around a general I<log()> method.

The level provided to I<log()> will be passed through to I<_log()> without modification;
it's up to your implementation of I<_log()> to handle these levels properly.  Note that
the level value can be a simple string corresponding to the level names, or could be the
numeric value of the level; either is acceptable.  It is recommended that subclasses
make use of the I<priority()> method to wrap the level value and eliminate confusion
in this area.

When a subclass' I<_log()> method is invoked through the public interface (i.e. via
I<log()>, I<emerg()>, I<alert()>, etc.), the logging priority level passed in will be
the numeric value.  Furthermore, assuming your subclasses do not override the basic
I<log()> operations, the level will have been validated, so a subclass does not need to
check that the priority level is in the valid range (unless a subclass only intends to
implement a subset of those priorities).

If you want to programmatically determine the name of the priority level based on the
numeric value, use the I<priority_name()> method.  This can be convenient if you want
to have prefixes that match up to the logging priority level, for instance.

=cut

my %priority = qw/
	emerg		0
	alert		1
	crit		2
	error		3
	warning		4
	notice		5
	info		6
	debug		7
/;

my %reverse_priority = map { $priority{$_} => $_ } keys %priority;

my $level_sub_fmt = <<'EOP';
sub %1$s {
	my $self = shift;
	return $self->log(q{%1$s}, @_);
}
EOP

for my $level (keys %priority) {
	eval sprintf ($level_sub_fmt, $level);
}

=pod

=head1 METHODS

The methods implemented by B<IC::Log::Base> fall into public-facing and internal-facing
groupings; the internal-facing methods are not in any way "private", but are not intended
for use by consumers of the logging system, instead being present to help out engineers
who are implementing their own loggers as subclasses of B<IC::Log::Base>

=head2 PUBLIC METHODS

=over

=item I<log( $level, $format, @args )>

Log a message/notification at the priority specified by I<$level>.  The I<$format>
and I<@args> are processed via I<sprintf()> to generate a full logging message to
pass to the underlying I<_log()> implementation.

The I<$level> is subject to validation; anything corresponding to a priority name
or numeric value is acceptable, but things outside that set of names or numeric range
will result in an exception being thrown (via use of I<validate_priority()>; a subclass
could alter this behavior as needed to introduce new logging levels, if desired).

The message formatting is achieved via use of I<format_message()>, passing through
I<$format> and I<@args> to it; therefore, subclasses can alter this behavior through
an override of I<format_message()>.

The means of actual logging (i.e. the logging mechanism itself) is ultimately up to
the subclass.  B<IC::Log::Base> has a simple, sane logging mechanism that would be
lamely suitable for use in simple one-off scripts and such, but any serious logging
needs would need something grander.  See the I<_log()> method for details.

=item priority-specific helper methods:

The following set of methods are all wrappers around I<log()>, passing through the
format and arguments given to them, but specifying the level as appropriate for the
method name:

=over

=item *

I<emerg( $format, @args )>

=item *

I<alert( $format, @args )>

=item *

I<crit( $format, @args )>

=item *

I<error( $format, @args )>

=item *

I<warning( $format, @args )>

=item *

I<notice( $format, @args )>

=item *

I<info( $format, @args )>

=item *

I<debug( $format, @args )>

=back

=back

=head2 INTERAL-FACING METHODS

=over

=item I<format_message( $format, @args )>

A simple message formatter; this method gets invoked by I<log()> and given the list
of arguments provided to I<log()> following the priority level; therefore, the actual
meaning of the arguments are rather open to interpretation, as subclasses are free
to override this method.

The default implementation passes through the list to I<sprintf()>, such that the
effective result is the I<$format>/I<@args> combination listed.  It is recommended
that subclasses not stray from this, and merely override I<format_message()> to add
extra logging-mechanism-specific details (perhaps adding PID, session IDs, etc. to
the messages, for instance).

=item I<priority( $level )>

Given a priority level name or numeric value in I<$level>, returns the canonical numeric
priority value associated with I<$level>, or I<undef> if no such value exists.  The
result is always numeric, though I<$level> can be numeric or a name.

=item I<validate_priority( $level )>

Similar to I<priority()>, except an exception is thrown if the I<$level> does not
resolve to a known priority level (i.e. it is an invalid name or a numeric value
outside the range of possible priorities).

=item I<priority_name( $level )>

Given a priority level name or number in I<$level>, returns the canonical priority
name associated with that $level.  Effectively the converse of I<priority()>.  This
uses I<validate_priority()>, and therefore throws an exception if I<$level> is
invalid.

=item I<_log( $level, $message )>

The primary method to override in order to implement a subclass with meaningful logging,
the I<log()> method is expected to carry out the actual logging duties to ensure that
the message specified by I<$message> is registered/logged/etc. in the manner appropriate
to the subclass and to the logging priority level specified by I<$level>.

The I<_log()> method is invoked by I<log()> and should not typically be used as part of
the public interface.  The I<$level> provided will have been validated by I<log()>,
and the I<$message> is the resulting formatted message based on the implementation of
I<format_message()>.  Therefore, a subclass can treat the I<$level> as reliable and the
I<$message> as fully ready-to-go.

The default behavior of I<_log()> is to simply print to STDERR, with the uppercase
priority name of I<$level> as a prefix and followed by the contents of I<$message>,
with a trailing newline.  This is fine for debugging simple scripts but is near
useless for any serious application.

=item I<_fallback_log( $level, $message )>

A thin wrapper around I<IC::Log::Base::_log()>, this is intended to always provide
a fallback logging technique to any subclass that wants to use it in the event that
the subclass finds the run environment unable to handle the logging facility implemented
by the subclass.  It is not intended that this method be overridden for this reason; it
passes along our default of printing to STDERR (see I<_log()> for details) as a safe
fallback throughout the inheritance hierarchy.

=back

=cut

sub format_message {
	my $self = shift;
	my $format = shift;
	return sprintf ($format, @_);
}

sub priority {
	my ($self, $level) = @_;
    return $level if $level =~ /^\d$/;
	return $priority{ lc ($level) };
}

sub validate_priority {
    my ($self, $level) = @_;
    my $valid_level = $self->priority($level);
    die "Invalid logging level $level specified.\n"
        unless defined($valid_level)
        and $valid_level =~ /^\d+$/
        and $valid_level >= 0
        and $valid_level <= 7
    ;
    return $valid_level;
}

sub priority_name {
    my ($self, $level) = @_;
    return $reverse_priority{ $self->validate_priority($level) };
}

sub log {
	my ($self, $level, @msg_args) = @_;
	return
		$self->_log(
			$self->validate_priority($level),
			$self->format_message(@msg_args)
		);
}

sub _log {
	my ($self, $level, $msg) = @_;
    $level = $self->priority_name($level);
	print STDERR "\U$level:\E $msg\n";
	return 1;
}

sub _fallback_log {
	my $self = shift;
	return _log($self, @_);
}

1;

__END__

=pod

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
