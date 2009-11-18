package Test::CacheHandlers::A;
use IC::Controller::PageCache;
use base qw(IC::Controller::PageCache);

sub set {
    my $self = shift;
    return $self->identifier;
}

sub get {
    my $self = shift;
    my %opt = @_;
    return $self->identifier() . ": $opt{key}";
}

sub identifier {
    my $class = shift;
    return $class;
}

package Test::CacheHandlers::B;
use base qw(Test::CacheHandlers::A);

1;
