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
