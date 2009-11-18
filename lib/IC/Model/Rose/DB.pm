package IC::Model::Rose::DB;

use strict;
use warnings;

use Rose::DB;
use base qw( Rose::DB );

=cut
use Moo::Config;

my $conf = 'Moo::Config';
$conf->parse();

# Use a private registry for this class
__PACKAGE__->use_private_registry;

# Set the default domain and type
__PACKAGE__->default_domain('production');
__PACKAGE__->default_type('main');

# Register the data sources

# Production:

__PACKAGE__->register_db(
    domain   => 'production',
    type     => 'main',
    driver   => 'Pg',
    database => $conf->parameter('PGDATABASE') || undef,
    host     => $conf->parameter('PGHOST') || undef,
    username => $conf->parameter('SQLUSER') || undef,
    password => $conf->parameter('SQLPASS') || undef,
);
=cut

sub standard_base_configuration {
    my $invocant = shift;
    die 'standard_base_configuration() only available as a package method!'
        if ref $invocant
    ;
    $invocant->use_private_registry;
    $invocant->default_domain('production');
    $invocant->default_type('main');
    return;
}

# override register_db to enforce common defaults for BC (domain, type, driver)
sub register_db {
    my $invocant = shift;
    my %params = @_;
    my %defaults = qw(
        domain      production
        type        main
        driver      pg
    );
    for my $default (keys %defaults) {
        $params{$default} = $defaults{$default}
            if ! defined $params{$default}
        ;
    }
#    use Data::Dumper ();
#    printf STDERR "Parameters for register_db after defaults: %s\n", Data::Dumper::Dumper(\%params);
    return $invocant->SUPER::register_db( %params );
}

# We're using a lexical variable to hold the first instance created,
# such that this package and any subclass packages can each get a singleton
# handle by default, stored in %singleton_repository keyed by the package name.
# Each class MUST provide one and only one domain/type handle or this system
# breaks down.

my %singleton_repository;

sub new {
    my $invocant = shift;
    my %args = @_;
    if (! delete $args{override_singleton}) {
        my $class = ref($invocant) || $invocant;
        $singleton_repository{$class} ||= $invocant->SUPER::new( %args );
        return $singleton_repository{$class};
    }
    else {
        return $invocant->SUPER::new( %args );
    }  
}

sub clear_singleton {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
	delete $singleton_repository{$class};
	return;
}

1;

__END__
