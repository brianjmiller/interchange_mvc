package IC::Cache;

use strict;
use warnings;

use Cache::Memcached::Fast;
use File::Spec;

#
# TODO: make this configurable
#
my @servers = (
    File::Spec->catfile(
        Interchange::Deployment->base_path,
        'var',
        'run',
        'memcached.socket',
    ),
);

sub new {
    my $self = shift;

    return Cache::Memcached::Fast->new(
        {
            servers => \@servers,
            @_,
        },
    );
}

1;
