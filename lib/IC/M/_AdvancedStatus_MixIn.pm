#
# classes using this mixin should implement two methods:
#
#     _mixin_model_descriptor:
#
#       returns a name that can be used to identify the model being acted on
#
#     _get_change_status_struct:
#
#       returns a structure that is a hash of hash refs where the keys of the 
#       outer hash represent statuses that an object is changing from, with 
#       the keys of the inner hash being statuses that an object is changing 
#       to whose value is callback subroutine to run when the transition occurs
#
#############################################################################
package IC::M::_AdvancedStatus_MixIn;

use strict;
use warnings;

use base qw( Rose::Object::MixIn );

__PACKAGE__->export_tag(
    all => [
        qw(
            change_status
        ),
    ],
);

#
# TODO: add modified_by handling
#
sub change_status {
    my $self       = shift;
    my $new_status = shift;
    my $args       = { @_ };

    unless (defined $new_status) {
        IC::Exception->throw( q{Can't change status missing argument: new status} );
    }

    my $field = delete $args->{_field} || 'status_code';

    my $content = '';
    if (UNIVERSAL::can($self, 'log_actions')) {
        if (defined $args->{content} and $args->{content} ne '') {
            $content = $args->{content};
        }

        my @additional_details = ();
        if (defined $args->{addtl_details}) {
            unless (ref $args->{addtl_details} eq 'ARRAY') {
                IC::Exception->throw("Can't change status, invalid addtl details argument: $args->{addtl_details} (not an ARRAY ref)");
            }

            for my $element (@additional_details) {
                unless (ref $element eq 'HASH') {
                    IC::Exception->throw("Can't change status, invalid addtl detail element: $element (not a HASH ref)");
                }
                for my $key qw( ref_code value ) {
                    unless (defined $element->{$key} and $element->{$key} ne '') {
                        IC::Exception->throw("Can't change status, invalid addtl detail, missing key/value: $key");
                    }
                }
            }

            @additional_details = @{ $args->{addtl_details} };
        }

        $self->add_action_log(
            {   
                action_code => 'status_change' . ($field ne 'status_code' ? " ($field)" : ''),
                content     => $content,
                details     => [
                    {   
                        ref_code => 'from',
                        value    => $self->$field,
                    },
                    {   
                        ref_code => 'to',
                        value    => $new_status,
                    },
                    @additional_details,
                ],
            },
        );
    }

    my $orig_status = $self->$field;
    $self->$field($new_status);
    $self->save;

    my $return;
    if (UNIVERSAL::can($self, '_get_change_status_struct')) {
        my $status_struct = $self->_get_change_status_struct;
        my $descriptor    = $self->_mixin_model_descriptor;

        if (exists $status_struct->{$field}) {
            $status_struct = $status_struct->{$field};
        }

        # must handle all statuses even if handling is a no-op
        if (exists $status_struct->{$orig_status}) {
            if (exists $status_struct->{$orig_status}->{$new_status}) {
                my $sub_ref = $status_struct->{$orig_status}->{$new_status};

                if (ref $sub_ref eq 'CODE') {
                    $return = $sub_ref->($self, _orig_status => $orig_status, _new_status => $new_status, %$args);
                }
                else {
                    IC::Exception->throw("Can't change $descriptor $field: $orig_status to $new_status not a subroutine");
                }
            }
            else {
                IC::Exception->throw("Can't change $descriptor $field: can't change from '$orig_status' to '$new_status' ($content)");
            }
        }
        else {
            IC::Exception->throw("Can't change $descriptor $field: unrecognized old $field '$orig_status' ($content)");
        }
    }
    
    return $return;
}

1;

#############################################################################
__END__
