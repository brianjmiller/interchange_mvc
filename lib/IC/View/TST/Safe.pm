package IC::View::TST::Safe;

use strict;
use warnings;

use Safe;
use Safe::Hole;
use Text::ScriptTemplate;
use IC::View::Base;
use Scalar::Util qw(blessed);
use Moose;

extends qw(IC::View::Base);

__PACKAGE__->register();

has _safe_hole => (is => 'rw', isa => 'Safe::Hole');
has _safe => (is => 'rw', isa => 'Safe');

sub valid_extensions {
	return qw(
		tst
	);
}

sub files_preferred { return 1; }

sub _prepare_data {
    my ($self, $data) = @_;
    my $result;
    if (blessed($data)) {
        my $hole = $self->_safe_hole() || $self->_safe_hole( Safe::Hole->new );
        $result = $hole->wrap( $data );
    }
    elsif (ref($data) eq 'ARRAY') {
        $result = [ map { ref($_) ? $self->_prepare_data($_) : $_ } @$data ];
    }
    elsif (ref($data) eq 'HASH') {
        $result = {
            map {
                $_ => ref($data->{$_})
                    ? $self->_prepare_data($data->{$_})
                    : $data->{$_}
            }
            keys %$data
        };
    }
    else {
        $result = $data;
    }
    return $result;
}

sub render {
	my ($self, $file, $marshal) = @_;
	my $template = Text::ScriptTemplate->new;
#printf STDERR "%s\::render() called for file $file!\n", __PACKAGE__, $file;
	$template->load( $file );
    my $safe = $self->_safe( Safe->new );
    $self->_safe_hole( undef );
#printf STDERR "%s\::render() created Safe compartment with root '%s'\n", __PACKAGE__, $safe->root;
    $safe->permit( qw(:base_core :base_math sort require entereval) );
    if ($marshal and ref($marshal) eq 'HASH') {
        $marshal = $self->_prepare_data($marshal);
        $template->setq( %$marshal );
    }
    my $hole;
    for my $module (@{ $self->helper_modules }) {
        next unless $module->can('export_symbols');
        my @share;
        for my $symbol ( $module->export_symbols ) {
            if ($symbol !~ /^&/) {
                push @share, $symbol;
            }
            else {
                my ($subname) = ( $symbol =~ /^&(.+)$/);
                $subname = "${module}::$subname";
                my $subref;
                {
                    no strict 'refs';
                    $subref = \&$subname;
                }
                $hole ||= $self->_safe_hole() || $self->_safe_hole( Safe::Hole->new );
#printf STDERR "Wrapping %s in safe hole with symbol %s...\n", $subname, $symbol,;
                $hole->wrap( $subref, $safe, $symbol );
            }
        }
        $safe->share_from( $module, \@share ) if @share;
    }

    eval {
        $self->content( $template->fill(PACKAGE => $safe) );
    };
    
    $self->_safe_hole( undef );
    $self->_safe( undef );
    
	die 'An error occured when rendering the view: ' . $@
		if $@
	;
    
	return;
}

sub parse {
    my ($path, $opt) = @_;
#::logDebug("IC::View::TST::parse started up with " . ::uneval($opt));

    my $template = Text::ScriptTemplate->new;
    # remove ths cache call until I know how to handle it -- Ethan
    # $template->cache($opt->{path});
    $template->load($path);
    
    my %vars = (
        Carts => $::Carts,
        CGI_array => \%CGI::values_array,
        CGI => \%CGI::values,
        Config => $Vend::Cfg,
        Discounts => $::Discounts,
        Document => Vend::Document->new,
        Filter => \%Vend::Interpolate::Filter,
        Items => $Vend::Items,
        Scratch => $::Scratch,
        Session => $::Session,
        Sub => Vend::Subs->new,
        Tag => Vend::Tags->new,
        Values => $::Values,
        Variable => $::Variable,
        opt => $opt,
    );
    if (ref($opt) eq 'HASH') {
        for my $var (keys %$opt) {
            ::logError(
                "Skipping template variable '%s'; the name conflicts with a core variable",
                $var
            ), next
                if exists $vars{$var};
            $vars{$var} = $opt->{$var};
        }
    }
    $template->setq(%vars);

    my $safe = Safe->new;
    my $hole = Safe::Hole->new;
    my $result;
    eval {
        $result = $template->fill(PACKAGE => 'IC::View::TST::Eval');#$safe);
    };
    
    if ($@) {
        ::logError("Template fill action failed for view '%s':\n%s", $path, $@);
        return undef;
    }

    return $result;
}

1;

__END__

=pod

=head1 NAME

IC::View::TST -- Interchange view plugin for Text::ScriptTemplate, enabling basic ASP-style Perl

=head1 SYNOPSIS

This module provides support for ASP-style Perl within MVC Interchange's view processing functionality
(as implemented via B<IC::View> and B<IC::View::Base>).

While Interchange Tag Language (ITL) is still available for use within MVC Interchange, ITL does not
fit very well into an object-oriented idiom. 
Furthermore, ITL itself does not really allow for use of "helper modules" effectively, as the Interchange
Safe module preparation is not fully exposed with a clean interface.  Therefore, B<IC::View::TST>
addresses this issues directly, allowing easy use of objects and complex data structures within views,
and implementing support for the "helper module" interface (see B<IC::Controller::HelperBase>).

See B<Text::ScriptTemplate> for details about the view language itself.  It's quite simple and easy to
learn.

=head1 METHODS

In addition to the usual things inherited from B<IC::View::Base>, the following method is implemented
within B<IC::View::TST>:

=over

=item B<render( $view_filename, $marshal_hash )>

Will attempt to render the file specified by I<$view_filename> using B<Text::ScriptTemplate>,
preparing a Safe compartment (see the B<Safe> module for more details) for evaluation of the embedded
Perl.  The name/value pairs specified in the I<$marshal_hash> hashref will be marshaled into the Safe
compartment, meaning that they are available as local variables within the embedded Perl.  In addition,
the routines exported by modules listed in the B<helper_modules()> attribute will also be imported
into the Safe compartment.

When marshalling the data, any blessed references found in the I<$marshal_hash> structure are wrapped
with B<Safe::Hole>.  This means that any object you pass in should be fully operational within the
context of the view (though there will always be corner cases where this is not true).  The I<$marshal_hash>
structure is recursively walked to accomplish this, meaning that nested arrays and hashes will have their
contents wrapped as appropriate.  Note that for hashes only the values are wrapped; if you for some odd
reason used a blessed reference as a hash key, that hash key would not be wrapped.

The resulting content from this operation will, as usual go to the B<content()> attribute of the
B<IC::View::TST> instance.

=back

=head1 CREDITS

Original author: Ethan Rowe (ethan@endpoint.com)

=cut
