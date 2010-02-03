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
