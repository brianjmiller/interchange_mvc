package IC::ManageRole::Properties;

use Moose::Role;

with 'IC::ManageRole::Base';
with 'IC::ManageRole::ObjectSaver';

has '+_prototype' => (
    default => 'FormWrapper',
);

around 'ui_meta_struct' => sub {
    #warn "IC::ManageRole::Properties::ui_meta_struct";
    my $orig = shift;
    my $self = shift;

    my $struct = $self->_ui_meta_struct;

    $struct->{+__PACKAGE__} = 1;

    return $self->$orig(@_);
};

no Moose;

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
