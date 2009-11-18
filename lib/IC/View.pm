package IC::View;

use strict;
use warnings;

use Moose;
use File::Spec;
use IC::View::Base;
use IC::View::ITL;
use IC::View::TST;

=pod

=head1 NAME

IC::View

=head1 SYNOPSIS

Provides basic interface and behaviors for pluggable view types (rendering engines); the top-level IC::View package
can be used to invoke any of the view plugins, by default basing the view type on the filename extension on the request
view file.

=head1 USAGE

=head1 ATTRIBUTES

All attributes are Moose-style attributes, meaning they are accessed via methods to set/get; the same method name
functions as both accessor and mutator, performing a mutator function if passed an argument, and otherwise acting
as a simple accessor.

=over

=item B<base_path>

The base path under which all views are expected to live.

=item B<default_extension>

The default filename extension to attempt to use on any view file (used if the view file requested does not have a 
specified extension).  If the file with the default extension exists, then it will be used.  Otherwise, the extensions
known to View::Base will be tried in alphabetical order until a view file is found.

=back

=cut

has base_path => ( is => 'rw', );
has default_extension => ( is => 'rw', default => sub { return 'html' }, );
has helper_modules => ( is => 'rw', isa => 'ArrayRef', default => sub { return [] } );

=pod

=head1 METHODS

=over

=item B<render( $view_file [, %$marshal_hash ] )>

Determines the relevant view type based on the view filename, invokes the underlying view object, and returns
the rendered results (a scalar, though not necessarily a simple scalar).

The B<$view_file> may be provided as an arrayref, in which case the list of files specified are searched until one is found; the
first such file found is rendered and all others are ignored.

I<$marshal_hash> is an optional hashref containing name/value pairs that should be marshaled into the view's evaluation
space as "variables"; the actual marshaling is up to the view object itself, as the marshaling needs to be done in a
manner idiomatic to the view type.

=back

=cut

sub render {
	my ($self, $file, $marshal) = @_;

	my $view = $self->identify_file( $file );
	# This ought to be a real exception object, when we're ready for that level of elegance
	confess "Can't find view file, looked in: " . (ref $file ? join ', ', @$file : $file) unless $view;

	my $view_engine = $self->get_view_object( $view );
	# Also deserves a real exception object
	confess 'No view object found for view ' . $view unless $view_engine;

    $view_engine->helper_modules( $self->helper_modules );
	$self->type_sensitive_render( $view_engine, $view, $marshal );
	return $view_engine->content;
}

sub type_sensitive_render {
	my ($self, $engine, $view, $marshal) = @_;

	my $target;
	my $preference_sub = $engine->can('files_preferred');
	if ( ! ($preference_sub and $engine-> $preference_sub() ) ) {
		$target = $self->slurp_view( $view );
	}
	else {
		$target = $view;
	}

	return $engine->render( $target, $marshal );
}

sub slurp_view {
	my ($self, $view) = @_;
	local $/ = '';
	open(my $fh, '<', $view)
		or confess 'Could not open view for reading!'
	;
	my $result = <$fh>;
	close $fh;
	return $result;
}

sub get_view_object {
	my ($self, $view) = @_;

	my ($extension) = ($view =~ /\.(\S+)$/);
	return undef unless defined $extension;

	for my $class (IC::View::Base->view_classes) {
		return $class->new
			if $class->handles( $extension )
		;
	}
	
	return;
}

sub identify_file {
	my ($self, $file) = @_;
	my @files;
	if (ref $file eq 'ARRAY') {
		@files = @$file;
	}
	else {
		push @files, $file;
	}

	my $view;
	while (!$view and @files) {
		$view = $self->find_view_file( shift @files );
	}

	return $view;
}

sub find_view_file {
	my ($self, $file) = @_;

	my $full_path = File::Spec->canonpath(
		File::Spec->file_name_is_absolute( $file )
			? $file
			: File::Spec->catfile($self->base_path, $file)
	);

	if ($full_path !~ /\.\S+$/) {
	    my @try_extensions = ();
	    for my $class (IC::View::Base->view_classes) {
		    push @try_extensions, $class->valid_extensions;
	    }
	    @try_extensions = sort @try_extensions;
	    unshift @try_extensions, $self->default_extension;
	    for (@try_extensions) {
		    my $tmp_path = $full_path . ".$_";
		    return $tmp_path if -e $tmp_path
	    }
	    return undef;
	}

	return -e $full_path ? $full_path : undef;
}

sub parse {
    my ($opt) = @_;

    if (defined($opt) and ref($opt) ne 'HASH') {
        die "Invalid arguments passed to &__PACKAGE__::parse -- expected nothing or a hashref";
    }
    $opt ||= {};

    $opt->{type} ||= $Vend::Cfg->{ViewType};

    $opt->{dir} ||= File::Spec->catfile($Vend::Cfg->{ViewDir}, $opt->{type});
    unless (defined($opt->{controller})) {
        die "No controller specified in call to &__PACKAGE__::parse";
    }
    defined($opt->{file})
        or $opt->{file} = 'index.html';
    $opt->{path} = File::Spec->catfile($opt->{dir}, $opt->{controller}, $opt->{file});

    delete $CGI::values{mv_nextpage};

    no strict 'refs';
    return &{"IC::View::$opt->{type}::parse"}->($opt);
}

1;

__END__
