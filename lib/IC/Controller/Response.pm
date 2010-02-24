package IC::Controller::Response;

use strict;
use warnings;

use Moose;
use IC::Controller::Response::Headers ();

=pod

=head1 NAME

IC::Controller::Response -- Simple object for representing the different
portions of a response (presumably HTTP).

=head1 DESCRIPTION

IC::Controller::Response defined a simple interface for a general "response"
object; for now, the response consists of headers and a buffer.  The headers
are encapsulated within a IC::Controller::Response::Headers instance, so
refer there for more information.  The buffer holds the content that is the
actual body of the response.  It is stored as a scalar reference, to reduce
overhead of buffer manipulations by using references instead of copying lengthy
strings excessively.

=head1 USAGE

Pretty straightforward; work with the buffer as an attribute, and use the underlying
headers object to manipulate the response headers.

  my $response = IC::Controller::Response->new;
  $response->headers->status( '200 OK' );
  $response->headers->content_type( 'text/html; charset="utf-8"' );
  $response->buffer( \$some_big_content_string );
  
  # You don't have to set the buffer with a scalar reference; it will still
  # store the content as a reference internally
  $response->buffer( 'I am not a reference, but I\'ll be stored as one!' );
  
  # The buffer, regardless of how it was set, always returns a scalar ref
  print ${ $response->buffer };

=head1 ATTRIBUTES

=over

=item B<headers( [ $some_response_headers_object ] )>

Get/set the underlying IC::Controller::Response::Headers object; this is
auto-instantiated on-demand by default, so there's really little reason at
present to use it as a mutator.  Use it as an accessor, though, to get at the
headers object in order to manipulate the headers of the current response.

=item B<buffer( [ $some_scalar_or_scalar_ref ] )>

Get/set the buffer for the response object; should be set to a scalar or scalar
ref; it will B<always> return as a scalar ref, for performance reasons.

=back

=cut

my $class = __PACKAGE__;

has headers => (
	is => 'rw',
	default => sub {
		my $header_class = $class . '::Headers';
		return $header_class->new;
	},
);

has buffer => (
	is => 'rw',
);

around buffer => sub {
	my $code = shift;
	my $self = shift;
	return $self->$code unless @_;
	my $value = shift;
	return $self->$code(
		!defined($value) || ref($value) eq 'SCALAR'
			? $value
			: \$value
	);
};

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
