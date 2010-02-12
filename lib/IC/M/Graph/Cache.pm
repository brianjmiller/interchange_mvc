package IC::M::Graph::Cache;

use IC::M::Graph;

use Moose::Role;

with 'IC::M::Graph';
requires qw(
    build_cache
    clear_cache
    retrieve_cache
);

around initialize_map => sub {
    my ($continuation, $self) = @_;

    my $result = $self->retrieve_cache;
    unless (defined $result) {
        $result = $self->$continuation();
        $self->build_cache($result);
    }

    return $result;
};

1;

__END__
