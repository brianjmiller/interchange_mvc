#
# TODO: add wrapper around deletion that prevents orphaned files
#
package IC::M::File;

use strict;
use warnings;

use base qw( IC::Model::Rose::Object );

use File::Copy qw();
use File::MimeInfo::Magic qw();
use File::Path qw( );
use File::Spec qw( );

use IC::Config;
#use IC::M::File::Property;
#use IC::M::FileResource;

__PACKAGE__->meta->setup(
    table => 'ic_files',
    columns => [
        id               => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'ic_files_id_seq' },

        __PACKAGE__->boilerplate_columns,

        file_resource_id => { type => 'integer' },
        object_pk        => { type => 'text', not_null => 1 },
    ],
    unique_key => [ 'file_resource_id', 'object_pk' ],
    foreign_keys => [
        file_resource => {
            class       => 'IC::M::FileResource',
            key_columns => {
                file_resource_id => 'id',
            },
        },
    ],
    relationships => [
        properties => {
            type => 'one to many',
            class => 'IC::M::File::Property',
            key_columns => {
                id => 'file_id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

#
#
#
sub manage_description {
    my $self = shift;
    return ($self->id || 'Unknown File');
}

=begin Storage Rationale:

    Decided on /uncontrolled/<table>/<pk>/<resource without table> because it seemed to be
    the best balance between human accessibility via the filesystem itself and facilitation
    of removal of all of the files associated with a given row in a table. Removal of a
    resource would be tedious in this case which seems the least likely to occur frequently.
    Removal or changing of a table name itself would still be trivial which may or may not
    be more likely than a resource removal.

    Other options:

    /uncontrolled/<resource>/<pk> - which amounts to /uncontrolled/<table>/<resource rest>/<pk>
    which is possibly the most human accessible but is a pain to remove files associated with
    a deleted record as it requires looping over the resources.

    /uncontrolled/files/<files.pk> - which is terribly inaccessible for humans, compounded by
    the fact that the directory index underneath "files/" would become overwhelming. Obviously
    it would be very easy to remove a single file, but would require looping to remove all files
    associated with a particular reference object.

=end

=cut

#
# in either a relative or non-relative version
# and includes check against actual file existence
# itself
#
sub local_path {
    my $self = shift;
    my $args = { @_ };

    $args->{relative} ||= 0;

    my $_htdocs_path = $self->_htdocs_path;

    my $local_glob = File::Spec->catfile(
        $_htdocs_path,
        $self->_sub_path,
        'current.*',
    );

    my @local_files = glob $local_glob;
    if (@local_files == 1) {
        if ($args->{relative}) {
            my $full_path_file = $local_files[0];
            $local_files[0] =~ s/$_htdocs_path//;
        }
        return $local_files[0];
    }
    elsif (@local_files > 1) {
        warn qq{Multiple "current" file revisions (system inconsistent): $local_glob\n};
    }

    return;
}

#
# syntactic sugar
#
sub url_path {
    my $self = shift;

    return $self->local_path( relative => 1 );
}

sub get_mimetype {
    my $self = shift;

    my $path = $self->local_path;
    return unless defined $path;

    return File::MimeInfo::Magic::magic($self->local_path);
}

sub store {
    my $self      = shift;
    my $from_file = shift;
    my $args = { @_ };

    unless (-e $from_file) {
        Bikes::Exception->throw("Can't store file: from file does not exist ($from_file)");
    }
    unless (-r $from_file) {
        Bikes::Exception->throw("Can't store file: from file not readable ($from_file)");
    }
    unless (defined $args->{extension} and $args->{extension} ne '') {
        Bikes::Exception->throw("Can't store file: extension argument missing or empty");
    }

    my $permanent_path = File::Spec->catfile(
        $self->_htdocs_path,
        $self->_sub_path,
    );

    my $permanent_path_exists = 0;
    if (-e $permanent_path) {
        unless (-d $permanent_path) {
            Bikes::Exception->throw("Can't store file: Permanent path is not a directory ($permanent_path)");
        }
        unless (-w $permanent_path) {
            Bikes::Exception->throw("Can't store file: Permanent path is not writable ($permanent_path)");
        }
        $permanent_path_exists = 1;

        # check to see if we already have a "current" file, if so need to (re)move it
        my @current = glob "$permanent_path/current.*";
        if (@current) {
            for my $file (@current) {
                unlink $file or die qq{Can't store file: failure to remove previously existing "current" file ($file)};
            }
        }
    }
    unless ($permanent_path_exists) {
        umask 0002;

        File::Path::mkpath($permanent_path);
    }

    my $permanent_file = File::Spec->catfile(
        $permanent_path,
        "current.$args->{extension}",
    );

    if ($args->{copy}) {
        unless (File::Copy::copy($from_file, $permanent_file)) {
            Bikes::Exception->throw("File copy failed: $!");
        }
    }
    else {
        unless (File::Copy::move($from_file, $permanent_file)) {
            Bikes::Exception->throw("File move failed: $!");
        }
    }
    return;
}

#
# relative path without file information
# for use by C<local_path> and C<store>
#
sub _sub_path {
    my $self = shift;

    my $table = ${ $self->file_resource->get_all_parents( as_object => 1 ) }[-2]->lookup_value;

    return File::Spec->catfile(
        'uncontrolled',
        $table,
        $self->object_pk,
        $self->file_resource->sub_path,
    );
}

#
# helper sub
#
sub _htdocs_path {
    return IC::Config->adhoc_htdocs_path;
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
