package IC::Controller::Request;

use strict;
use warnings;

use Moose;

=pod

=head1 NAME

IC::Controller::Request -- Simple object for representing and accessing information
regarding an HTTP request within Interchange.

=head1 DESCRIPTION

This object module provides a minimal interface for representing HTTP request
structures; it is built around the internal structures Interchange uses for
holding HTTP headers, CGI parameters, etc.  The object interface allows consumers
of this module to decouple their code to some extent from the idiosyncracies of
Interchange request representation internals; as long as the IC::Controller::Request
instance is given the proper headers and CGI hashes, that instance will provide
a cleaner interface to the underlying data.

=head1 USAGE

The constructor call is really the only place where your code needs to be coupled
much with Interchange core code:

  my $request = IC::Controller::Request->new(
      headers => ::http()->{env}, # where the global http headers hash lives
      cgi     => \%CGI::values,   # the global CGI parameters,
  );

However, once you have an instance of IC::Controller::Request, getting at
common header information, cookies, etc. is pretty straightforward:

  if ($request->https_on) {
      print 'SSL activated!';
  }
  else {
      print 'No SSL!';
  }
  
  # get/post
  printf 'The %s request method was used.', $request->method;
  
  # be restfully read-only with your CGI variables!
  my %vars;
  if ($request->method eq 'post') {
      %vars = $request->post_variables;
  }
  else {
      %vars = $request->get_variables;
  }

And of course access to cookies is considerably saner:

  for my $cookie ($request->cookies) {
      printf 'cookie name %s has value %s', $cookie->{name}, $cookie->{value};
  }
  
...or...

  my $cookie_value = $request->get_cookie($cookie_name);

=head1 ATTRIBUTES

All attributes are Moose-style, meaning each accessor is a get/set function.

There are other attributes within this object not documented here; they aren't
documented because they are not intended for general, direct use.  You can use
them, but such use isn't supported or recommended.

=over

=item B<headers( [ $hashref ] )>

Attribute holding the hashref for Interchange's internal representation of
http request headers.  The standard http header names are reassigned within
Interchange, such that the actual header names available aren't effectively
documented or widely understood.  Consequently, the purpose of this attribute
is simply to set the hashref for a IC::Controller::Request instance; once
done, accessing common http headers like 'method' or 'https_on' should be
done through the methods on the instance.

Defaults to an empty hashref; typical use would be to set this, within an
Interchange request, to ::http()->{env}.

=item B<cgi( [ $hashref ] )>

Attribute holding the hashref for Interchange's internal representation of
HTTP GET/POST variables (%CGI::values).  Long-standing practices within the
Interchange community include modifying these variables during the regular
handling of a request.  This object module seeks to modify that practice, by
effectively rendering these variables "read-only" by default; therefore,
best use of this module is to set this attribute at instantiation time, but
then only work with these parameters through the restfully-oriented
B<get_variables()> and B<post_variables()> methods, which are read-only versions
of the data.

Note that the B<get_variables()> and B<post_variables()> methods will only cleanly
map the general B<cgi> parameters if the cryptic Interchange global
B<$Global::TolerateGet> is perly-false (the default); if $Global::TolerateGet is true,
then Interchange will include GET variables in this space alongside POST variables
within a POST request.

Note that Interchange's method of handling PUT variables is less established
than is the GET/POST handling, and therefore hasn't been taken into consideration
for this object's interface.

=item B<cookies( [ $arrayref ] )>

Holds the list of cookies for this request; while this is technically an attribute
of the object, it is derived from the underyling cookie header within B<headers>
by default.  You can work around this behavior by setting this attribute directly,
but do so at your own risk.  Better to let the object calculate this list for you.

Returns a list of hashrefs, with each hashref representing a single cookie, with
a 'name' parameter and a 'value' parameter.

If there are no cookies, this will simply return an empty list.

=back

=cut

has headers => ( is => 'rw', isa => 'HashRef', default => sub { return {}; }, );
has cgi     => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { return {}; },
);
has cookies => (
	is => 'rw',
	isa => 'ArrayRef',
);

has cookie_header_name => ( is => 'rw', default => sub { return 'HTTP_COOKIE' }, );
has method_header_name => ( is => 'rw', default => sub { return 'REQUEST_METHOD' }, );
has https_on_header_name => ( is => 'rw', default => sub { return 'HTTPS' }, );

around cookies => sub {
	my $code = shift;
	my $self = shift;
	my $result = $self->$code( @_ );
	return @$result if defined $result;
	return $self->reset_cookies;
};

around headers => sub {
	my $code = shift;
	my $self = shift;

	my $result = $self->$code(@_);
	$self->cookies( [] ) if @_;

	return $result;
};

sub reset_cookies {
	my $self = shift;
	my $cookies = $self->headers->{ $self->cookie_header_name } || '';
	my @cookies;
	@cookies
		= map {
			my ($name, $value) = split /=/, $_, 2;
			{ name => $name, value => $value, };
		}
		split(/;\s+/, $cookies)
		if $cookies =~ /\S/
	;
	return $self->cookies(\@cookies);
}

=pod

=head1 METHODS

The purpose of the various methods is to provide read-only access to commonly-needed
http headers as well as the GET/POST variables from the request.  All of these
methods derive their information from the underlying B<cgi> and B<headers>
attributes.

=over

=item B<method()>

Returns the HTTP request method used (in lower-case).

=item B<https_on()>

Returns the underlying HTTP header indicated the https status of the request.
Perly-true if HTTPS was used, perly-false otherwise.


=item B<get_variables()>

Returns a hash (in list form, not by reference) of the GET variables for this
request.  Will return an empty list if B<method()> is not 'get'.  See the B<cgi>
attribute for more information.

=item B<post_variables()>

Returns a hash (in list form, not by reference) of the POST variables for this
request.  Will return an empty list if B<method()> is not 'post'.  See the B<cgi>
attribute for more information.

=item B<reset_cookies()>

Recalculates the cookie list within the B<cookies> attribute, based on the
underlying cookies header in the B<headers> attribute.  Though this is primarily
intended for internal use, it can be used to force a reset if you (mired as you
must be in bad habits) happen to fiddle with the underlying headers manually.

=item B<get_cookie( I<$name_of_cookie> )>

Returns the value of the requested cookie. If requested cookie doesn't exist, returns undef.

=back

=cut

sub method {
	my $self = shift;
	return lc $self->headers->{ $self->method_header_name };
}

sub https_on {
	my $self = shift;
	return $self->headers->{ $self->https_on_header_name };
}

sub get_variables {
	my $self = shift;
	my %empty;
	return %empty unless $self->method =~ /^get$/i;
	return %{ $self->cgi };
}

sub post_variables {
	my $self = shift;
	my %empty;
	return %empty unless $self->method =~ /^post$/i;
	return %{ $self->cgi };
}

sub get_cookie {
	my ($self, $name) = @_;

	for my $cookie ($self->cookies) {
		if ($cookie->{name} eq $name) {
			(my $cookie_value = $cookie->{value}) =~ s/\%([0-9A-F]{2})/chr(hex($1))/ieg;
			return $cookie_value;
		}
	}
		
	# If we got this far the cookie doesn't exist.
	return undef;
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
