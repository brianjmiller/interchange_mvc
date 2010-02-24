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

	confess( q{Can't register view class: already registered} ) if grep { $_ eq $package } @subclasses;
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

=pod

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
