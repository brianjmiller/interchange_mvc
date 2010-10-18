package IC::M::_Tree_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

__PACKAGE__->export_tag(
    all => [
        qw(
            get_all_parents
            get_all_descendents
        ),
    ],
);

#
# see alternate_implementation after which is the version 
# with the view, it was slower in some initial testing likely 
# do to the fact that the view isn't really materialized
# but if the view were to be actually materialized (which I'd
# think it could be easily) then that implementation should be
# re-tested/benchmarked
#
sub get_all_parents {
    my $self = shift;
    my $args = { @_ };

    $args->{as_object} ||= 0;
    
    my @parents;
    
    my $obj = $self;
    while (my $parent = $obj->parent) {
        if ($args->{as_object}) {
            push @parents, $parent;
        }
        else {
            push @parents, $parent->id;
        }
    
        $obj = $obj->parent;
    }

    return wantarray ? @parents : \@parents;
}

=begin alternate_implementation

#
# this is the version that works against the view, which actually
# seems to be slower, likely because the view isn't truly materialized
# so has to be regenerated for each call
#
sub get_all_parents {
    my $self = shift;
    my $args = { @_ };

    $args->{as_object} ||= 0;

    my $leaf = $self->leaf;

    my $parents = [ split '~', $leaf->branch ];
    if ($args->{as_object}) {
        my $class = ref $self;
        my $class_mgr = $class . '::Manager';
        $parents = $class_mgr->get_objects(
            query => [
                parent_id => $parents,
            ],
        );
    }

    return wantarray ? @$parents : $parents;
}

=end alternate_implementation

=cut

sub get_all_descendents {
    my $self = shift;
    my $args = { @_ };

    $args->{as_object} ||= 0;

    my %descendents;
    my @children = @{ $self->children };

    for my $child (@children) {
        %descendents = (%descendents, map { $_->id => $_ } ($child, @{ $child->get_all_descendents( as_object => 1 ) }));
    }

    return $args->{as_object}
        ? wantarray ? values %descendents : [ values %descendents ]
        : wantarray ? keys %descendents : [ keys %descendents ]
    ;
}

1;

__END__

=pod

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see: http://www.gnu.org/licenses/ 

=cut
