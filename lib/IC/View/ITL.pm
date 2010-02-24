package IC::View::ITL;

use strict;
use warnings;

use Vend::Interpolate;

use base qw(IC::View::Base);

__PACKAGE__->register();

sub valid_extensions {
	return qw(
		html
		itl
	);
}

=pod

=head1 NAME

IC::View::ITL

=head1 SYNOPSIS

Implements the IC::View-type rendering behaviors for Interchange's ITL (Interchange
Templating Language).  Expects to receive raw ITL content in the render call, which
is interpolated and returned.

=head1 METHODS

=over

=item B<render( $content [, %$marshal_hashref ] )>

Interpolates B<$content> for ITL, placing the result in the instance's B<content> attribute.
When B<$marshal_hashref> is provided, all the data within is marshaled into ITL's B<Stash>
space.  The B<Stash> space hash is restored to its previous state after interpolation,
such that the marshalled data is not available in subsequent interpolation unless the content
ITL takes steps to preserve that data.

=back

=cut

# Marshals the $marshal data into $Vend::Interpolate::Stash; restores the stash after interpolation,
# so marshalled data does not persist in subsequent interpolation within the same process.

sub render {
	my ($self, $content, $marshal) = @_;

	my ($data, %stash, @restore_keys, @delete_keys);
	$data = $Vend::Interpolate::Stash ||= {};
	if (ref $marshal eq 'HASH') {
		@delete_keys = keys %$marshal;
		@restore_keys = grep { exists $data->{$_} } @delete_keys;
		@stash{@restore_keys} = @$data{@restore_keys};
		@$data{@delete_keys} = @$marshal{@delete_keys};
	}

	$self->content(
		Vend::Interpolate::interpolate_html( $content )
	);

	delete @$data{@delete_keys} if @delete_keys;
	@$data{@restore_keys} = @stash{@restore_keys} if @restore_keys;
	return;
}

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
