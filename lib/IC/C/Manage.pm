=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::Manage;

use strict;
use warnings;

use IC::M::ManageFunction;
use IC::M::Right;

use base qw( IC::C );

# the application subclass should register itself as the provider of the 'manage' controller
#__PACKAGE__->registered_name('manage');

sub menu {
    my $self = shift;

    return $self->forbid unless $self->check_right('access_site_mgmt');

    $self->content_title('Site Management Menu');
    $self->content_subtitle('');

    my $role = $self->role;

    my $context = $self->context;
    $context->{menu_left}  = [] unless defined $context->{menu_left};
    $context->{menu_right} = [] unless defined $context->{menu_right};

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

    if (defined $authorized_functions) {
        my $sections = {};
        for my $function (sort { $a->sort_order <=> $b->sort_order } @$authorized_functions) {
            push @{ $sections->{ $function->section->display_label } }, {
                url           => $self->url(
                    controller => 'manage',
                    action     => 'function',
                    parameters => {
                        _function => $function->code,
                    },
                ),
                display_label => $function->display_label,
                #extra_params  => $function->extra_params,
                secure        => 1,
            };
        }

        my $num_sections = keys %$sections;
        $num_sections++ if ($num_sections % 2);
        my $half_sections = $num_sections / 2;

        my $menu  = [];
        my $index = 0;
        my $count = 0;
        for my $section (sort keys %$sections) {
            $index = 1 if ($count >= $half_sections);

            push @{ $menu->[$index] }, {
                name  => $section,
                links => $sections->{$section},
            };
            $count++;
        }
        $context->{menu_left}  = $menu->[0];
        $context->{menu_right} = $menu->[1];
    }

    $self->render( context => $context );

    return;
}

sub function {
    my $self = shift;

    return $self->forbid unless $self->check_right('access_site_mgmt');

    my $params = $self->parameters;

    my $function = $params->{_function};
    my $step     = $params->{_step};

    unless ($function =~ /(.*)_(.*)$/) {
        IC::Exception->throw("Invalid manage function format: $function");
    }

    my $function_obj = IC::M::ManageFunction->new( code => $function )->load;
    unless ($self->check_right( 'execute', $function_obj )) {
        IC::Exception->throw('Role ' . $self->role->display_label . " can't execute $function");
    }

    my $_subclass = $1;
    my $_method   = $2;

    my $subclass = $_subclass;
    $subclass =~ s/__/::/g;

    my $custom_package_prefix = IC::Config->smart_variable('MVC_MANAGE_PACKAGE_PREFIX');

    my $class      = $custom_package_prefix . $subclass;
    my $class_file = $class . '.pm';
    $class_file    =~ s/::/\//g;
    unless (exists $INC{$class_file}) {
        eval "use $class";
        if ($@) {
            my $tried = $class;
            my $orig  = $@;

            $class      = 'IC::Manage::' . $subclass;
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

    my $manage;
    eval {
        $manage = $class->new(
            _class      => $_subclass,
            _method     => $_method,
            _step       => $step,
            _controller => $self,
        );
    };
    if (my $e = IC::Exception->caught()) {
        IC::Exception->throw("Can't instantiate manage class: $e");
    }

    my $result = eval {
        $manage->execute;
    };
    if (my $e = IC::Exception->caught()) {
        IC::Exception->throw("Failed manage execution (explicitly): $e");
    }
    elsif ($@) {
        IC::Exception->throw("Failed manage execution: $@");
    }

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
