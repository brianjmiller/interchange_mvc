=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::Manage::Widget::Menu;

use strict;
use warnings;

use JSON ();

use IC::M::ManageMenuItem;
use IC::M::Right;

use Moose;
extends qw( IC::C );
no Moose;

# the application subclass should register itself as the provider of the 'manage' controller
__PACKAGE__->registered_name('manage/widget/menu');

sub config {
    my $self = shift;

    my $struct = {
        click_to_activate => JSON::true(),
        nodes             => [],
    };

    my $su = $self->is_superuser;

    #
    # all actions associated with a given menu item node will need to be
    # checked for privilege so just get them all and check them all at
    # once then when we walk the menu we can just reference the check
    #
    my $check_privileged = [
        map {
            $_->manage_class_action
        } @{
            IC::M::ManageMenuItem::Manager->get_objects(
                query => [
                    '!manage_class_action_id' => undef,
                ],
            ),
        },
    ];

    my $privileged;
    if ($su) {
        $privileged = $check_privileged;
    }
    else {
        #
        # we have finer grained control over actions, so we are not calling 
        # the controller's check_right
        #
        $privileged = $self->role->check_right(
            'execute',
            $check_privileged,
        );
    }

    my $branch_sort_map = {
        map {
            $_->id => $_->pos
        } @{
            IC::M::ManageMenuItemLeaf::Manager->get_objects();
        },
    };

    if (defined $privileged) {
        my $privileged_by_id = {};

        for my $action (@$privileged) {
            $privileged_by_id->{$action->id} = 1;
        }

        #
        # now walk the list of nodes identifying branches where
        # *any* leaf has an action that is privileged, in the 
        # case that it does it should be included in the menu
        #
        my $top_node = IC::M::ManageMenuItem->new( id => 1 )->load;
        for my $node (sort { $branch_sort_map->{$a->id} <=> $branch_sort_map->{$b->id} } @{ $top_node->children }) {
            my $config = _node_config($node, $privileged_by_id, $branch_sort_map);
            next unless defined $config;

            push @{ $struct->{nodes} }, $config;
        }
    }

    my $response = $self->response;
    $response->headers->status('200 OK');
    $response->headers->content_type('text/plain');
    #$response->headers->content_type('application/json');
    $response->buffer( JSON::encode_json( $struct ));

    return;
}

sub _node_config {
    my $node = shift;
    my $privileged = shift;
    my $sort_map = shift;

    my $alo = 0;
    if (defined $node->manage_class_action_id and $privileged->{ $node->manage_class_action_id }) {
        $alo = 1;
    }
    else {
        my $descendents = $node->get_all_descendents( as_object => 1 );

        for my $descendent (@$descendents) {
            next unless (defined $descendent->manage_class_action_id and $privileged->{ $descendent->manage_class_action_id });

            $alo = 1;
            last;
        }
    }

    return unless $alo;

    my $ref = {
        label => $node->lookup_value,
    };

    if (defined $node->manage_class_action) {
        $ref->{action} = {
            baseclass => $node->manage_class_action->class_code,
            subclass  => $node->manage_class_action->code,
            args      => $node->manage_class_action_addtl_args,
        };
    }

    for my $child (sort { $sort_map->{$a->id} <=> $sort_map->{$b->id} } @{ $node->children }) {
        my $config = _node_config($child, $privileged);
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
