=begin description

This is really just a function that is generic enough to be leveraged
to easily create MixIns that can then be included by models having a
desire to use dispatch table based triggers.

Classes using mixins leveraging this code should implement two methods:

    _mixin_model_descriptor:

        returns a name that can be used to identify the model being acted on

    _get_trigger_structure_method as passed in:

        returns a structure that is a hash of hash refs where the keys of the 
        outer hash represent statuses that an object is changing from, with 
        the keys of the inner hash being statuses that an object is changing 
        to whose value is callback subroutine to run when the transition occurs

See _AdvancedStatus_MixIn and _AdvancedKind_MixIn for examples.

=end description

=cut 

package IC::M::_Dispatch_Trigger_MixIn;

use strict;
use warnings;

#
# TODO: add modified_by handling
#
sub _change_value_with_trigger {
    my $self      = shift;
    my $new_value = shift;
    my $args      = { @_ };

    unless (defined $new_value) {
        IC::Exception->throw( q{Can't change value missing argument: new value} );
    }

    my $field = delete $args->{_field};
    unless (defined $field) {
        IC::Exception->throw( q{Can't change value missing argument: _field} );
    }

    my $get_trigger_structure_method = delete $args->{_get_trigger_structure_method};
    unless (defined $get_trigger_structure_method) {
        IC::Exception->throw( q{Can't change value missing argument: _get_trigger_structure_method} );
    }

    $args->{no_logging} ||= 0;

    my $content = '';
    if (UNIVERSAL::can($self, 'log_actions') and ! $args->{no_logging}) {
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
                action_code => ($args->{_action_code} ne '' ? $args->{_action_code} : 'change_value' . " ($args->{_field})"),
                content     => $content,
                details     => [
                    {   
                        ref_code => 'from',
                        value    => $self->$field,
                    },
                    {   
                        ref_code => 'to',
                        value    => $new_value,
                    },
                    @additional_details,
                ],
            },
        );
    }

    my $orig_value = $self->$field;
    $self->$field($new_value);
    $self->save;

    #
    # TODO: fix this based on new docs in UNIVERSAL
    #
    my $return;
    if (UNIVERSAL::can($self, $get_trigger_structure_method)) {
        my $change_struct = $self->$get_trigger_structure_method;
        my $descriptor    = $self->_mixin_model_descriptor;

        if (exists $change_struct->{$field}) {
            $change_struct = $change_struct->{$field};
        }

        # must handle all transitions even if handling is a no-op
        if (exists $change_struct->{$orig_value}) {
            if (exists $change_struct->{$orig_value}->{$new_value}) {
                my $sub_ref = $change_struct->{$orig_value}->{$new_value};

                if (ref $sub_ref eq 'CODE') {
                    $return = $sub_ref->($self, _orig_value => $orig_value, _new_value => $new_value, %$args);
                }
                else {
                    IC::Exception->throw("Can't change $descriptor $field: $orig_value to $new_value not a subroutine");
                }
            }
            else {
                IC::Exception->throw("Can't change $descriptor $field: can't change from '$orig_value' to '$new_value' ($content)");
            }
        }
        else {
            IC::Exception->throw("Can't change $descriptor $field: unrecognized old $field '$orig_value' ($content)");
        }
    }
    
    return $return;
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
