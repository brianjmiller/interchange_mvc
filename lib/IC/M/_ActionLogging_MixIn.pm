package IC::M::_ActionLogging_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

__PACKAGE__->export_tag(
    all => [
        qw(
            log_actions
        ),
    ],
);

#
# TODO: add modified_by handling
#
sub log_actions {
    my $self = shift;

    return;
}

1;

__END__
