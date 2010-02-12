package IC::View::TST;

use strict;
use warnings;

use Text::ScriptTemplate;
use IC::View::Base;
use Scalar::Util qw(blessed);
use Moose;
use Moose::Util::TypeConstraints;
use IC::View::TST::Eval;

extends qw(IC::View::Base);

__PACKAGE__->register();

has _safe_hole => (is => 'rw');
has _safe      => (is => 'rw');

sub valid_extensions {
	return qw(
		tst
	);
}

sub files_preferred { return 1; }

my $compartment = 0;
sub render {
	my ($self, $file, $marshal) = @_;
	my $template = Text::ScriptTemplate->new;
    #printf STDERR "%s\::render() called for file $file!\n", __PACKAGE__, $file;
	$template->load( $file );

    my $obj = IC::View::TST::Eval->new;

    #printf STDERR "%s\::render() using namespace %s\n", __PACKAGE__, $namespace;
    if ($marshal and ref($marshal) eq 'HASH') {
        $template->setq( %$marshal );
    }
    for my $module (@{ $self->helper_modules }) {
        next unless $module->can('export_symbols');
        my @share;
        for my $symbol ( $module->export_symbols ) {
                push @share, $symbol;               
        }
        $obj->share_from( $module, \@share ) if @share;
    }
    
	eval {
        $self->content( $template->fill( PACKAGE => $obj->root) );
    };
    
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

    my $result;
    my $obj = IC::View::TST::Eval->new;
    eval {
        $result = $template->fill(PACKAGE => $obj->root);
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

Will attempt to render the file specified by I<$view_filename> using B<Text::ScriptTemplate>, using
Safe-like compartmentalization to prevent variables from bleeding from one iteration to the next.
Unlike Safe, this compartment imposes no restrictions on operations. The name/value pairs specified 
in the I<$marshal_hash> hashref will be marshaled into the compartment, meaning that they are 
available as local variables within the embedded Perl.  In addition, the routines exported by modules
listed in the B<helper_modules()> attribute will also be imported into the Safe compartment.

The resulting content from this operation will, as usual go to the B<content()> attribute of the
B<IC::View::TST> instance.

=back

=head1 CREDITS

Original author: Ethan Rowe (ethan@endpoint.com)
Safe restrictions removed by: JT Justman (jt@endpoint.com)
=cut
