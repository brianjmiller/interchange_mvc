package IC::Controller::Response::Headers;

use strict;
use warnings;

use Moose;

=pod

=head1 NAME

IC::Controller::Response::Headers -- simple module for handling basic
HTTP headers in a responose

=head1 DESCRIPTION

The IC::Controller::Response::Headers module is basically a glorified
hash, providing convenience methods for working with common HTTP headers
in an underlying raw headers hash, but also allowing direct access to the
underlying hash for less common headers that do not have convenience methods.

Ultimately, the headers within the object's hash can be returned in a form
appropriate for an HTTP response, and the order of the headers will be
dictated initially by the B<header_order> method and then by alphabetical
sorting of remaining headers.

=head1 USAGE

All the headers within an instance live within the hash acccessible via
the B<raw> attribute; convenience methods can be used for the more common
headers:

  my $headers = IC::Controller::Response::Headers->new;
  # set status line for bounce, with location as well.
  $headers->status( '302 moved' );
  $headers->location( 'http://www.endpoint.com' );
  # The underlying headers in the raw() attribute will match up;
  # this prints "302 moved to http://www.endpoint.com"
  print $headers->raw->{Status} . ' to ' . $headers->raw->{Location};
  
  # Suppose we want to send some custom header; that's fine.  Use the raw hash.
  $headers->raw->{'X-Bogus'} = 'some_bogus_header_value';

When you're ready to send a response and need the headers formatted properly,
use the B<headers()> method.

  # The method is list/scalar context-sensitive.
  # @response will get a list of header entries, each consisting of
  # "Header-Name: header-value"
  my @response = $headers->headers;
  
  # while $response will get similar content, except each header separated by "\r\n"
  # rather than as a list of headers.
  my $response = $headers->headers;

=head1 SUBCLASSING

The primary purpose of subclassing would be to add more convenience methods
or to add specialized logic around existing convenience methods.

There's some magic going on in this package that should be understood for
the purpose of subclassing.  The B<header_mapping> method returns a list of
name/value pairs (i.e. a hash) corresponding to helper methods and their underlying
raw header names.  To add convenience functions that simply map from a friendly
method name to a raw header, you need only add a name/value pair to the result
of this method.  From there, you would call B<__PACKAGE__->make_mapped_methods()>
to build the helper methods in __PACKAGE__'s symbol table.

Since your subclass inherits from IC::Controller::Response::Headers, and this
module already uses this technique to create helper methods, you do not need to
concern yourself with your subclasses ensuring that their overridden version of
B<header_mapping> includes the base class' values.  Your subclass will inherit
the helper methods the base class already has, which are determined when this
module is compiled.

=head1 ATTRIBUTES

=over

=item B<raw( [ $hashref ] )>

Get/set the raw headers hash; each hash key corresponds to the header name
as it would be sent in the HTTP response, with the value being the value that
would be sent with that header.

There is no checking of headers at this time; you can stick any arbitrary value
into the raw hash.  The purpose of the module isn't to ensure correctness (at this
time, anyway); it's to make things easy.

=back

=cut

has raw => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		return {};
	},
);

has cookies => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		return {};
	},
);

=pod

=head1 METHODS

=over

=item B<header_mapping()>

Returns a list of name/value pairs corresponding respectively to helper method
names and their underlying header names in the B<raw> hash.

There's no real use for this when working with instances of this module, but you
may want to override it for subclasses.

=item B<create_mapped_methods()>

Builds the helper methods for get/set access to common headers in the B<raw>
hash, based on the name/value pairs from B<header_mapping()>.  There's no need
to ever use this method directly, unless you want to subclass this module and
want your subclass to have its own helper methods.

=item B<header_order()>

Returns a list of header names as they would appear in the B<raw> hash in the
order in which those headers should appear in the actual HTTP response.

=item B<headers()>

Returns the full set of headers, with headers appearing in B<header_order()> coming
first in the order specified therein, followed by all other headers in the B<raw>
hash in alphabetical order.

Each header will be formatted as "Header-Name: Header-Value".  When called in list
context, a list of such header/value strings will be returned.  When called in
scalar context, a single string is returned containing all header/value strings,
separated by "\r\n".

=item B<set_cookie({ I<attribute key/value pairs> })>

Stores cookies which will be set in the response headers.

Valid attributes are:

=over

=item B<name>

name of cookie

=item B<value>

optional data; if left blank, cookie value will be set to empty string.

=item B<expire>

optional expiration time for a persistent cookie (Thursday, 02-Jan-2010 00:00:00 GMT), or the form "30 days" or "7 weeks" or "60 minutes"; if not provided, cookie will be a session cookie only.

=item B<domain>

optional domain the cookie should apply to

=item B<path>

optional path the cookie should apply to

=back

=back

=cut

sub header_mapping {
	return qw(
		status			    Status
		content_type	    Content-Type
		content_disposition	Content-Disposition
		location		    Location
		target_window	    Target-Window
	);
}

sub create_mapped_methods {
	my $invocant = shift;
	confess 'May only be called against a package!'
		if ref $invocant
	;
	my %mappings = $invocant->header_mapping;
	for my $key (%mappings) {
		$invocant->create_mapped_method( $key, $mappings{$key} );
	}
	return;
}

my $magical_mapper = sub {
	my $self = shift;
	confess 'May only be called against an instance!'
		unless ref $self
	;
	my $header = shift;
	return $self->raw->{$header}
		unless @_
	;
	my $value = shift;
	if (defined $value) {
		$self->raw->{$header} = $value;
	}
	else {
		delete $self->raw->{$header};
	}
	return $value;
};

sub create_mapped_method {
	my $invocant = shift;
	confess 'May only be called against a package!'
		if ref $invocant
	;
	my ($symbol, $header) = @_;
	my $name = "${invocant}::$symbol";
	my $sub = sub {
		my $self = shift;
		return $self->$magical_mapper($header, @_);
	};
	no strict 'refs';
	*$name = $sub;
	return;
}

sub header_order {
	return qw(
		Status
		Location
		Content-Type
		Content-Disposition
	);
}

sub headers {
	my $self = shift;
	my (@results, %seen);
	my $raw = $self->raw;
	for my $header ($self->header_order) {
		next unless defined $raw->{$header};
		push @results, "$header: $raw->{$header}";
		$seen{$header}++;
	}
	for my $header (sort { $a cmp $b } grep { ! $seen{$_}++ } keys %$raw) {
		next unless defined $raw->{$header};
		push @results, "$header: $raw->{$header}";
	}

	if (wantarray) {
		return @results;
	}
	else {
		return join "\r\n", @results;
	}
}

sub set_cookie {
	my ($self, $opt) = @_;

	my $cookie = { %$opt };
	my $name = delete $cookie->{name};
	unless ($name and length($name)) {
		die "No cookie name given to __PACKAGE__ set_cookie method\n";
	}

	$self->cookies->{$name} = $cookie;

	return 1;
}

__PACKAGE__->create_mapped_methods;

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
