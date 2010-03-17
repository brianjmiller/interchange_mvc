package IC::M::_File_MixIn;

use strict;
use warnings;

use File::Basename qw(fileparse);
use File::MimeInfo::Magic qw();
use File::Spec qw();
use IO::Scalar;

use IC::Config;
use IC::M::FileResource;

use base qw( Rose::Object::MixIn );

__PACKAGE__->export_tag(
    all => [
        qw(
            get_file
            get_file_url
            get_file_resource_objs
            get_file_property_values
            store_file_for_resource
        ),
    ],
);

my $_file_resource_model_class     = 'IC::M::FileResource';

#
# Returns a IC::M::File object representing either the direct
# file, or an alternate file object that is considered a replacement
#
sub get_file {
    my $self = shift;
    my $args = { @_ };

    $args->{use_alternates} //= 1;

    my $resource = File::Spec->catfile( @{ $args->{resource} } );

    my $file_resource_objs = $self->get_file_resource_objs;
    my $file_resource_obj;
    for my $element (@$file_resource_objs) {
        if ($element->sub_path eq $resource) {
            $file_resource_obj = $element;
            last;
        }
    }
    # not finding a resource object can't throw an exception, 
    # because it is used for alternate objects which may not have 
    # this particular resource
    if (defined $file_resource_obj) {
        my $file = $file_resource_obj->get_file_for_object($self);
        if (defined $file) {
            return $file;
        }
    }

    return if not $args->{use_alternates};

    # file didn't exist, check to see if methods to retrieve alternate objects
    # which we might have better luck with was provided
    if (UNIVERSAL::can( $self, '_alt_file_objs' )) {
        my $alt_refs = $self->_alt_file_objs( resource => $args->{resource} );
        for my $alt_ref (@$alt_refs) {
            my $method = $alt_ref->{method};
            my $object = $self->$method;

            unless (UNIVERSAL::can( $object, 'get_file' )) {
                die "_alt_file_objs provided method that returned an object that can't get_file\n";
            }

            return $object->get_file( resource => $alt_ref->{resource} );
        }
    }

    return;
}

#
# Returns a IC::M::File object representing either the direct
# file, or an alternate file object that is considered a replacement
#
sub get_file_property_values {
    my $self = shift;
    my $properties = shift;
    my $args = { @_ };

    unless (defined $properties and ref $properties eq 'ARRAY' and @$properties) {
        IC::Exception->throw( q{Can't get file property values: properties not specified (correctly)} );
    }

    my $file = $self->get_file( %$args );
    unless (defined $file) {
        if (defined $args->{as_hash} and $args->{as_hash}) {
            return wantarray ? () : {};
        }
        return wantarray ? () : [];
    }

    return $file->property_values( $properties, %$args );
}

#
# syntactic sugar
#
# TODO: add flag for getting full URL, for use in e-mails for instance
#
sub get_file_url {
    my $self = shift;
    my $args = { @_ };

    my $file = $self->get_file( @_ );
    return unless defined $file;

    return $file->url_path;
}

#
# TODO: needs to be updated to handle recursion
#
sub get_file_resource_objs {
    my $self = shift;

    my $table_node = $_file_resource_model_class->new(
        parent_id    => 1,
        lookup_value => $self->meta->table,
    );
    unless ($table_node->load(speculative => 1)) {
        IC::Exception->throw("Can't retrieve file resource table node: " . $self->meta->table);
    }

    return $table_node->children;
}

#
#  Utility sub to store the indicated filesystem path for the object
#  in the indicated resource path.
#
sub store_file_for_resource {
    my ($self, $file, $resource, %args) = @_;
    my $res = ref $resource ? $resource->[0] : $resource;

    IC::Exception->throw("No such file '$file'")
      unless -e $file;

    my ($file_resource_obj) = grep { $_->lookup_value eq $res } @{$self->get_file_resource_objs};

    unless ($file_resource_obj) {
        IC::Exception->throw("Can't retrieve file resource table node: " . $resource);
    }
    
    my $attr = $file_resource_obj->attrs;
    my $attr_refs = [];

    if (@$attr) {
        if (defined $args{attrs}) {
            warn "Attributes provided: Don't know how to handle attributes yet!";
        }
    }

    my $db = $self->db;
    my $in_transaction = $db->dbh->ping == 3;

    eval {
        $db->begin_work unless $in_transaction;

        my $user_id = 'schema';

        my $file_obj = $file_resource_obj->get_file_for_object( $self );
        if (defined $file_obj) {
            $file_obj->modified_by( $user_id );
            $file_obj->save;
        }
        else {
            $file_resource_obj->add_files(
                {
                    db          => $db,
                    object_pk   => $self->serialize_pk,
                    created_by  => $user_id,
                    modified_by => $user_id,
                },
            );
            $file_resource_obj->save;

            $file_obj = $file_resource_obj->get_file_for_object( $self );
        }

        if (defined $attr_refs) {
            # TODO: make this more advanced to do updates when possible

            my $new_properties = [];
            for my $attr_ref (@$attr_refs) {
                push @$new_properties, {
                    file_resource_attr_id => $attr_ref->{id},
                    value                 => $attr_ref->{value} || '',
                    created_by            => $user_id,
                    modified_by           => $user_id,
                };
            }
            $file_obj->properties($new_properties);
            $file_obj->save;
        }

        my ($suffix) = $file =~ /\.(\w+)$/;

        $file_obj->store( $file, extension => $suffix, copy => 1 );
    };
    if ($@) {
        my $exception = $@;

        $db->rollback;

        die $exception;
    }

    $db->commit unless $in_transaction;
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
