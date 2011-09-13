=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::Manage::Widget::Dashboard;

use strict;
use warnings;

use JSON ();

use Moose;
extends qw( IC::C );
no Moose;

# the application subclass should register itself as the provider of the 'manage' controller
#__PACKAGE__->registered_name('manage/widget/dashboard');

sub data {
    #warn "IC::C::Manage::Widget::Dashboard::data";
    my $self = shift;

    my $struct = $self->_get_data_struct;

    my $response = $self->response;
    $response->headers->status('200 OK');
    $response->headers->content_type('text/plain');
    #$response->headers->content_type('application/json');
    $response->buffer( JSON::encode_json( $struct ));

    return;
}

sub _get_data_struct {
    my $self = shift;

    return {
        renderer => {
            type   => 'Tile',
            config => $self->_get_config_struct,
        },
    };
}

sub config {
    #warn "IC::C::Manage::Widget::Dashboard::config";
    my $self = shift;

    my $struct = $self->_get_config_struct;

    my $response = $self->response;
    $response->headers->status('200 OK');
    $response->headers->content_type('text/plain');
    #$response->headers->content_type('application/json');
    $response->buffer( JSON::encode_json( $struct ));

    return;
}

sub _get_config_struct {
    my $self = shift;
    return {
        title             => 'Dashboard',
        url               => $self->url(
            controller     => 'manage/widget/dashboard',
            action         => 'config',
            match_security => 1,
        ),
        polling_interval  => 10,
        polling_is_active => JSON::false(),
        actions           => {
            primary => {
                label      => 'Primary',
                is_default => JSON::true(),
                renderer   => $self->_get_primary_renderer_struct,
            },
        },
    };
}

sub _get_primary_renderer_struct {
    return {
        type   => 'Basic',
        config => {
            data => 'No custom dashboard content.',
        },
    };
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
