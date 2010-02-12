#
# TODO: check to see if IC::Graph could be leveraged in place of the file resource view
#
package IC::M::FileResource;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

use IC::M::File;
use IC::M::FileResourceLeaf;
use IC::M::FileResource::Attr;

__PACKAGE__->meta->setup(
    table => 'ic_file_resources',
    columns => [
        id                   => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_file_resources_id_seq' },

        __PACKAGE__->boilerplate_columns,

        parent_id            => { type => 'integer' },
        branch_order         => { type => 'integer' },
        lookup_value         => { type => 'varchar', length => 70, not_null => 1 },
        generate_from_parent => { type => 'integer' },
    ],
    unique_key => [ 'parent_id', 'lookup_value' ],
    foreign_keys => [
        parent => {
            class       => 'IC::M::FileResource',
            key_columns => {
                parent_id => 'id',
            },
        },
    ],
    relationships => [
        attrs => {
            type => 'one to many',
            class => 'IC::M::FileResource::Attr',
            key_columns => {
                id => 'file_resource_id',
            },
        },
        children => {
            type => 'one to many',
            class => 'IC::M::FileResource',
            key_columns => {
                id => 'parent_id',
            },
        },
        files => {
            type => 'one to many',
            class => 'IC::M::File',
            key_columns => {
                id => 'file_resource_id',
            },
        },
        leaf => {
            type        => 'one to one',
            class       => 'IC::M::FileResourceLeaf',
            key_columns => {
                id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->lookup_value || $self->id || 'Unknown File Resource');
}

#
# TODO: theoretically this works but we could use the view
#       record to pull the parents all at once, and it might
#       be better... though it might not, so it should be
#       benchmarked
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


#
# this is the portion of the path that does not include
# the object's PK nor the table, that can be constructed
# from the object itself, so this amounts to the resource
# directly along with all parents that are NOT the first
# two, aka the table and the artificial top node
#
sub sub_path {
    my $self = shift;

    my @parents = ($self);
    push @parents, $self->get_all_parents( as_object => 1 );

    # remove the artificial node, and the table node
    my $artificial_node = pop @parents;
    my $table_node      = pop @parents;

    my $path = File::Spec->catfile( map { $_->lookup_value } @parents );
    return $path;
}

sub get_file_for_object {
    my $self       = shift;
    my $ref_object = shift;

    my $files = $self->find_files(
        db    => $ref_object->db,
        query => [
            object_pk => $ref_object->serialize_pk,
        ],
    );
    if (@$files == 1) {
        return $files->[0];
    }
    elsif (@$files > 1) {
        IC::Exception->throw("Object + File Resource has more than one file (corruption occurred)");
    }

    return;
}

1;

__END__
