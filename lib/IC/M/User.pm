package IC::M::User;

use strict;
use warnings;

use Digest::MD5 ();
use Digest::SHA1 ();

use IC::M::RightTarget::User;

use base qw( IC::Model::Rose::Object );

__PACKAGE__->meta->setup(
    table => 'ic_users',
    columns => [
        id                        => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_users_id_seq' },

        __PACKAGE__->boilerplate_columns,

        role_id                   => { type => 'integer', not_null => 1 },
        version_id                => { type => 'integer', not_null => 1 },
        status_code               => { type => 'varchar', length => 30, not_null => 1 },
        username                  => { type => 'varchar', length => 30, not_null => 1 },
        email                     => { type => 'varchar', length => 100, not_null => 1 },
        password                  => { type => 'varchar', length => 40, not_null => 1 },
        password_hash_kind_code   => { type => 'varchar', length => 32, not_null => 1 },
        password_expires_on       => { type => 'date', },
        password_force_reset      => { type => 'boolean', not_null => 1, default => 'false' },
        password_failure_attempts => { type => 'smallint', not_null => 1, default => 0 },
        time_zone_code            => { type => 'varchar', length => 50, not_null => 1 },
    ],
    unique_key => [
        [ 'username' ],
    ],
    foreign_keys => [
        password_hash_kind => {
            class => 'IC::M::HashKind',
            key_columns => {
                password_hash_kind_code => 'code',
            },
        },
        role => {
            class => 'IC::M::Role',
            key_columns => {
                role_id => 'id',
            },
        },
        status => {
            class => 'IC::M::UserStatus',
            key_columns => {
                status_code => 'code',
            },
        },
        time_zone => {
            class => 'IC::M::TimeZone',
            key_columns => {
                time_zone_code => 'code',
            },
        },
        version => {
            class => 'IC::M::UserVersion',
            key_columns => {
                version_id => 'id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

sub manage_description {
    my $self = shift;
    return ($self->username || $self->email || 'Unknown User');
}

sub rights_class { 'IC::M::RightTarget::User' }

{
    my $_hash_kind_interface_map = {
        md5 => {
            lib  => 'Digest::MD5',
            func => 'md5_hex',
            call => 'Digest::MD5::md5_hex',
        },
        sha1 => {
            lib  => 'Digest::SHA1',
            func => 'sha1_hex',
            call => 'Digest::SHA1::sha1_hex',
        },
    };

    sub authenticate_credentials {
        my $invocant = shift;
        my %opt = @_;

        IC::Exception->throw('Class method called on instance: authenticate_credentials') if ref $invocant;

        for my $key (qw( username password )) {
            next if defined $opt{$key} and $opt{$key} =~ /\S/;

            IC::Exception::MissingValue->throw("Missing argument: $key");
        }

        my $password = delete $opt{password};

        my $user = IC::M::User->new(
            username => $opt{username},
            (defined $opt{db} ? (db => $opt{db}) : ()),
        );

        IC::Exception->throw("Unrecognized username: $opt{username}")
            unless $user->load( speculative => 1 );

        IC::Exception->throw("User is disabled: $opt{username}")
            if $user->status_code eq 'disabled';

        #
        # TODO: restore ability to specify password kind
        #
        my $hash_lookup = $_hash_kind_interface_map->{$user->password_hash_kind_code};
        IC::Exception->throw('Hash kind has no interface map: ' . $user->password_hash_kind_code)
            unless defined $hash_lookup;

        my $call = $hash_lookup->{call};
        my $check_password;
        {
            no strict 'refs';
            $check_password = &$call( $password );
        }
        IC::Exception->throw('Incorrect password')
            if $user->password ne $check_password;

        return $user;
    }
}

1;

__END__
