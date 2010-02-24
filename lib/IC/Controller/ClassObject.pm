package IC::Controller::ClassObject;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

subtype ActionList
    => as HashRef
    => where { 1 }
;

coerce ActionList
    => from ArrayRef
        => via { my %tmp = map { $_ => 1 } @$_; \%tmp; }
;

subtype CacheHandler
    => as Any
    => where {
        UNIVERSAL::can( $_, 'get_cache' ) || UNIVERSAL::can( $_, 'get' )
        and UNIVERSAL::can( $_, 'set_cache' ) || UNIVERSAL::can( $_, 'set' )
    }
;

subtype ControllerErrorHandler
    => as Any
    => where {
        my $val = $_;
        my $ref = ref($val);
        defined($val) and (
            !$ref && length($val)
            or $ref eq 'CODE'
        );
    }
;

has package => (is => 'rw', isa => 'Str',);
has content_type => (is => 'rw', isa => 'Str',);
has page_cache_handler => (is => 'rw', isa => 'Maybe[CacheHandler]' );
has helper_modules => (is => 'rw', isa => 'ArrayRef', auto_deref => 1, default => sub { return []; } );
has page_cache_no_reads => (is => 'rw', isa => 'Bool', default => sub { return 0 });
has error_handler => (is => 'rw', isa => 'ControllerErrorHandler');

my @actionlists = qw( cache_pages cache_actions );
has $_ => ( is => 'rw', isa => 'ActionList', coerce => 1, default => sub { return {} }, )
    for @actionlists
;

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
