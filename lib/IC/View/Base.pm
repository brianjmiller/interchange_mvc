package IC::View::Base;

use strict;
use warnings;

use Moose;

has content => ( is => 'rw', );
has helper_modules => ( is => 'rw', isa => 'ArrayRef', default => sub { return []; } );

sub handles {
	my ($invocant, $file) = @_;
	my $class = ref($invocant) || $invocant;
	return if $class eq __PACKAGE__;

	return 1 if grep(/^$file$/i, $class->valid_extensions);
	return;
}

my @subclasses;

sub register {
	my $package = shift;
	confess('Already registered!') if grep({ $_ eq $package } @subclasses);
	push @subclasses, $package;
	return $package;
};

sub files_preferred {
	return;
}

sub view_classes {
	my $invocant = shift;
	confess 'view_classes() only avaialble from ' . __PACKAGE__ . '-level call!'
		unless ! ref($invocant) and $invocant eq __PACKAGE__
	;

	return @subclasses;
}

sub render {}

1;

__END__
