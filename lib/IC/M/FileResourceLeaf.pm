package IC::M::FileResourceLeaf;
        
use strict;
use warnings;
            
use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_file_resources_tree_view',
    columns => [
        id            => { type => 'integer', not_null => 1, primary_key => 1 },
        parent_id     => { type => 'integer' },
        level         => { type => 'integer', not_null => 1 },
        branch        => { type => 'text', not_null => 1 },
        pos           => { type => 'integer', not_null => 1 },
    ],      
    foreign_keys => [
        parent => {
            class => 'IC::M::FileResourceLeaf',
            key_columns => {
                parent_id => 'id',
            },
        },
    ],
    relationships => [
        properties => {
            type        => 'one to one',
            class       => 'IC::M::FileResource',
            key_columns => {
                id => 'id',
            },
        },
    ],
    #
    # TODO: this is provided for in new RDBO's I believe
    #
    #view => '1',
);          

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift; 
    return ($self->id || 'Unknown File Resource Leaf');
}       
        
1;      
    
__END__ 
