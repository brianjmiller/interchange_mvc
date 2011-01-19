package IC::ManageRole::Tree;

use Moose::Role;

with 'IC::ManageRole::Base';

after 'ui_meta_struct' => sub {
    warn "IC::ManageRole::Tree::ui_meta_struct(after)";
    my $self = shift;
    my %args = @_;

    my $struct = $args{context}->{struct};

    $struct->{'IC::ManageRole::Tree::ui_meta_struct(after)'} = 1;

    $struct->{label} = 'Tree';

    $struct->{renderer} = {
        type   => 'PanelLoader',
        config => {
            loader_config => {
                type   => 'Tree',
                config => {
                    data => [],
                },
            },
            panel_config  => {
                data => {},
            },
        },
    };

    my $node_refs  = $struct->{renderer}->{config}->{loader_config}->{config}->{data};
    my $panel_data = $struct->{renderer}->{config}->{panel_config}->{data};

    my $tops = $self->_model_class_mgr->get_objects(
        with_objects => [ 'parent' ],
        query        => [
            '!parent_id'       => undef,
            'parent.parent_id' => undef,
        ],
        # TODO: this needs to be customizable, minimally label needs to match
        #       the field used in _node_config
        sort_by => 't1.branch_order, t1.label',
    );

    for my $top (@$tops) {
        my $config = $self->_node_config(
            $top,
            $panel_data,
            $args{context}->{controller},
            (@$tops == 1 ? (default_open => 1) : ()),
        );
        push @$node_refs, $config;
    }

    return;
};

no Moose;

sub _node_config {
    my $self = shift;
    my $node = shift;
    my $panel_data = shift;
    my $controller = shift;
    my %args = @_;

    my $ref = {
        id        => $node->id,
        # TODO: this needs to be customizable
        label     => $node->label,
        add_class => 'ic_renderer_panel_loader_control',
    };
    if (defined $args{default_open} and $args{default_open}) {
        $ref->{default_open} = JSON::true();
    }

    my $sub_struct = $panel_data->{ $node->id } = {};

    $self->object_ui_meta_struct(
        context => {
            controller => $controller,
            object     => $node,
            struct     => $sub_struct,
        },
    );

    for my $child (@{ $node->children }) {
        my $config = $self->_node_config($child, $panel_data, $controller);
        next unless defined $config;

        push @{ $ref->{branches} }, $config;
    }

    return $ref;
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
