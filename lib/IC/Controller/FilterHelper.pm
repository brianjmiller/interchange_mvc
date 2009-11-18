package IC::Controller::FilterHelper;

use Vend::Interpolate ();
use Vend::Util ();

use strict;
use warnings;

use Exporter;
use IC::Controller::HelperBase;
use File::Spec;

use base qw(Exporter IC::Controller::HelperBase);

use EndPoint::Config;

use vars qw/@EXPORT/;

Vend::Util::setup_escape_chars;

my @filters_to_export = qw/
	commify
	date_change
	compress_space
	null_to_space
	null_to_comma
	null_to_colons
	space_to_null
	colons_to_null
	digits_dot
	namecase
	name
	digits
	alphanumeric
	word
	unix
	dos
	mac
	no_white
	strip
	sql
	urlencode
	entities
	decode_entities
/;

my %export_as = qw/
	entities		escape_html
	decode_entities	unescape_html
	urlencode		escape_url
/;

my %filter_sub = %Vend::Interpolate::Filter;
# newer versions of IC have this split out of Vend::Interpolate into separate configuration files.
unless (%filter_sub) {
    # Blech.  Too bad the core IC configuration parsing
    # module is so supremely bad, otherwise we could actually
    # use it.
    my (%filter_flag, %filter_alias);
    for my $file (glob( File::Spec->catfile(EndPoint::Config->adhoc_ic_path, 'code', 'Filter', '*.filter'))) {
        open(my $fh, '<', $file) or die "Failed to open filter file '$file': $!\n";
        my ($in_string, $code, $marker);
        while ($_ = <$fh>) {
            if ($in_string) {
                if (/^$marker\n/) {
                    $in_string = undef;
                    $marker = undef;
                }
                else {
                    $filter_sub{$in_string} .= $_;
                }
            }
            else {
                next unless /^\s*CodeDef\s+(\w+)\s+([Ff]ilter|[Aa]lias|[Rr]outine)\s*(.*?)\s*$/;
                my ($name, $type, $value) = ($1, $2, $3);
                if (lc($type) eq 'filter') {
                    $filter_flag{$name}++;
                }
                elsif (lc($type) eq 'alias') {
                    $filter_alias{$name} = $value;
                }
                else {
                    if ($value =~ /^<<([A-Z]+)/) {
                        $marker = $1;
                        $in_string = $name;
                        $filter_sub{$name} = '';
                    }
                    else {
                        $filter_sub{$name} = $value;
                    }
                }
            }
        }
        close($fh) or die "Failed to close filter file '$file': $!\n";
    }
    for my $filter (keys %filter_sub) {
        if (!$filter_flag{$filter}) {
            delete $filter_sub{$filter};
        }
        else {
            $filter_sub{$filter} = eval $filter_sub{$filter};
        }
    }
    for my $filter (keys %filter_alias) {
        next unless $filter_flag{$filter} and $filter_sub{$filter_alias{$filter}};
        $filter_sub{$filter} = $filter_sub{$filter_alias{$filter}};
    }
}

for my $filter (@filters_to_export) {
	next unless ref $filter_sub{$filter} eq 'CODE';
	my $sub = $export_as{$filter} || $filter;
	no strict 'refs';
	*$sub = $filter_sub{$filter};
	push @EXPORT, $sub;
}

1;

__END__

=pod

=head1 NAME

IC::Controller::FilterHelper -- helper module for generating view routines
that provide Interchange filter features.

=head1 DESCRIPTION

Many of the filters provided by Interchange are quite useful for performing
mundane tasks or those otherwise requiring multiple regex manipulations to get
at the final value. This module makes those filters available as their own
subroutines in the user's namespace.

=head1 USAGE

For the list specfied (as some filters are inextricably reliant on running
within Interchange), the translation is roughly:

	$Tag->filter('foo',$val) => foo($val)

Some filter names have been overriden.

=head1 FUNCTIONS

It is assumed there is basic familiarity with the Interchange filters of the
same name. For those whose names are overriden, the mapping to the Interchange
filter is noted.

=over

=item B<commify>

=item B<date_change>

=item B<compress_space>

=item B<null_to_space>

=item B<null_to_comma>

=item B<null_to_colons>

=item B<space_to_null>

=item B<colons_to_null>

=item B<digits_dot>

=item B<namecase>

=item B<name>

=item B<digits>

=item B<alphanumeric>

=item B<word>

=item B<unix>

=item B<dos>

=item B<mac>

=item B<no_white>

=item B<strip>

=item B<sql>

=item B<escape_url>

Maps to the urlencode filter.

=item B<escape_html>

Maps to the encode_entities/entities filter.

=item B<unescape_html>

Maps to the decode_entities filter.

=back

=cut
