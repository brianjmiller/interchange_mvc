=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::Manage::Widget::Menu;

use strict;
use warnings;

use JSON::Syck ();

use IC::M::ManageFunction;
use IC::M::Right;

use Moose;
extends qw( IC::C );
no Moose;

# the application subclass should register itself as the provider of the 'manage' controller
__PACKAGE__->registered_name('manage/widget/menu');

sub config {
    my $self = shift;

    # we have finer grained control over functions, so we are
    # not calling the controller's check_right
    my $authorized_functions = $self->role->check_right(
        'execute',
        IC::M::ManageFunction::Manager->get_objects(
            query => [
                in_menu => 1,
            ],
        ),
    );

    my $struct = {};
    if (defined $authorized_functions) {
        my $sections = {};
        for my $function (sort { $a->sort_order <=> $b->sort_order } @$authorized_functions) {
            unless (exists $sections->{$function->section_code}) {
                $sections->{$function->section_code} = {
                    code          => $function->section_code,
                    display_label => $function->section->display_label,
                };
            }

            push @{ $sections->{ $function->section_code }->{functions} }, {
                code          => $function->code,
                display_label => $function->display_label,
            };
        }
        for my $section_code (sort keys %$sections) {
            push @{ $struct->{sections} }, $sections->{$section_code};
        }
    }

    my $response = $self->response;
    $response->headers->status('200 OK');
    $response->headers->content_type('text/plain');
    #$response->headers->content_type('application/json');
    $response->buffer( JSON::Syck::Dump( $struct ));

    return;
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
