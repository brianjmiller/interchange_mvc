package IC::M::Config;

use strict;
use warnings;

use IC::M::Config::Level;
use IC::M::Config::Setting;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table         => 'ic_config',
    columns       => [
        id           => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_config_id_seq' },

        __PACKAGE__->boilerplate_columns,

        setting_code => { type => 'varchar', length => 50, not_null => 1 },
        level_code   => { type => 'varchar', length => 30, not_null => 1 },
        ref_obj_pk   => { type => 'text' },
    ],
    unique_key    => [ qw( setting_code level_code ref_obj_pk ) ],
    foreign_keys  => [
        level => {
            class       => 'IC::M::Config::Level',
            key_columns => {
                level_code => 'code',
            },
        },
        setting => {
            class       => 'IC::M::Config::Setting',
            key_columns => {
                setting_code => 'code',
            },
        },
    ],
    relationships => [
        values => {
            type => 'one to many',
            class => 'IC::M::Config::Value',
            key_columns => {
                id => 'config_id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->setting_code . ' - ' . $self->level_code . ' for ' . $self->ref_obj_pk || 'Unknown Config');
}

sub get {
    my $self = shift;
    my $setting_code = shift;
    my $args = { @_ };

    unless (defined $setting_code and $setting_code ne '') {
        IC::Exception->throw(q{Can't get config setting: setting code not provided or empty});
    }

    $args->{global} ||= 0;

    #
    # pull setting + values in reverse priority order for levels
    # available, check whether values should cascade and/or be
    # combined, basically do what we got to do
    #
    my $setting = IC::M::Config::Setting->new(
        code => $setting_code,
    );
    unless ($setting->load(speculative => 1)) {
        IC::Exception->throw("Unrecognized setting: $setting_code");
    }

    my $levels = [];
    for my $level_map (@{ $setting->level_map }) {
        if (defined $args->{$level_map->level_code}) {
            #
            # the global settings are special, they don't have a ref_obj_pk
            #
            if ($level_map->level_code eq 'global') {
                if ($args->{global}) {
                    push @$levels, (
                        and => [
                            level_code => 'global',
                            ref_obj_pk => undef,
                        ],
                    );
                }
            }
            else {
                push @$levels, (
                    and => [
                        level_code => $level_map->level_code,
                        ref_obj_pk => $args->{$level_map->level_code}->as_hashkey,
                    ],
                );
            }
        }

        #
        # stop processing if a level was passed in that was a level we care about
        #
        last if (not $setting->should_cascade and @$levels);
    }

    unless (@$levels) {
        IC::Exception->throw(q{Can't determine setting value: no levels found});
    }

    my $configs = IC::M::Config::Manager->get_objects(
        require_objects => [ 'level' ],
        with_objects    => [ 'values.option' ],
        query           => [
            setting_code => $setting_code,
            or           => $levels,
        ],
    );
    return unless @$configs;

    my $values = [];
    for my $config (sort { $b->level->priority <=> $a->level->priority } @$configs) {
        push @$values, map { $_->code } map { $_->option } @{ $config->values };

        last unless ($setting->should_combine and @$values);
    }

    return wantarray ? @$values : $values;
}

{
    #
    # TODO: make this DB stored to allow applications to create their own levels
    #
    my $kind_model_class_map = {
    };
    sub reference_obj {
        my $self = shift;

        #
        # TODO: need to make this handle multiple field PKs
        #
        my $obj_model_class = $kind_model_class_map->{$self->level_code};
        my ($pk_field)      = $obj_model_class->meta->primary_key_columns;

        my $object = $obj_model_class->new(
            $pk_field => $self->ref_obj_pk,
        )->load;

        return $object;
    }
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
