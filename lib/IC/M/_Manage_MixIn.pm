package IC::M::_Manage_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

__PACKAGE__->export_tag(
    all => [
        qw(
            load_lib
        ),
    ],
);

#
# load the Perl lib that corresponds to this model object, either
# a manage class or a manage class action
#
sub load_lib {
    my $self = shift;

    my $table = $self->meta->table;

    my $_class;
    my $_subclass;
    if ($table eq 'ic_manage_classes') {
        $_class = $self->code;
    }
    elsif ($table eq 'ic_manage_class_actions') {
        $_class    = $self->class_code;
        $_subclass = $self->code;
    }
    else {
        IC::Exception->throw("Can't load library for manage model: unrecognized table '$table'");
    }

    $_class =~ s/__/::/g;
    if (defined $_subclass) {
        $_class .= "::$_subclass";
    }
    
    my $custom_package_prefix = IC::Config->smart_variable('MVC_MANAGE_PACKAGE_PREFIX');
    
    my $class = $custom_package_prefix . $_class;
    
    my $class_file = $class . '.pm';
    $class_file    =~ s/::/\//g;
    unless (exists $INC{$class_file}) {
        eval "use $class";
        if ($@) {
            my $tried = $class;
            my $orig  = $@;

            $class      = 'IC::Manage::' . $_class;
            $class_file = $class . '.pm';
            $class_file =~ s/::/\//g;
            unless (exists $INC{$class_file}) {
                eval "use $class";
                if ($@) {
                    IC::Exception->throw("Can't load Manage class ($tried or $class): $orig or $@");
                }
            }
        }
    }

    return $class;
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
