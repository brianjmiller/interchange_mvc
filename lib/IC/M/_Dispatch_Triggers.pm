=begin description

These are really just functions that are generic enough to be leveraged
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

package IC::M::_Dispatch_Triggers;

use strict;
use warnings;

#
# Verify that an object is allowed to change a value for a given field.
# There are two modes:
#
# 1. Can change from current to a specific value
# 2. Can change from current to *something*, but we don't care what
#
sub _can_change_value {
    my $self      = shift;
    my $new_value = shift;
    my $args      = { @_ };

    my @caller        = caller(1);
    my $caller_simple = sprintf '%s line %s', @caller[1,2];

    my $field = delete $args->{_field};
    unless (defined $field) {
        IC::Exception->throw( qq{Can't check for possible change in value missing argument: _field ($caller_simple)} );
    }

    #warn sprintf "_can_change_value: $self, $field, %s, $new_value ($caller_simple)\n", $self->$field;

    my $get_trigger_structure_method = delete $args->{_get_trigger_structure_method};
    unless (defined $get_trigger_structure_method) {
        IC::Exception->throw( qq{Can't check for possible change in $field missing argument: _get_trigger_structure_method ($caller_simple)} );
    }

    my ($check, $message) = (1, '');

    if ($self->can($get_trigger_structure_method)) {
        my $change_struct = $self->$get_trigger_structure_method;
        my $descriptor    = $self->_mixin_model_descriptor;

        if (exists $change_struct->{$field}) {
            $change_struct = $change_struct->{$field};
        }

        my $orig_value = $self->$field;
        if (exists $change_struct->{$orig_value}) {
            if (defined $new_value) {
                if (exists $change_struct->{$orig_value}->{$new_value}) {
                    my $sub_ref = $change_struct->{$orig_value}->{$new_value};

                    if (ref $sub_ref eq 'HASH' && ref $sub_ref->{check} eq 'CODE') {
                        $message = $sub_ref->{check}->($self, _orig_value => $orig_value, _new_value => $new_value, %$args);
                    }
                }
                else {
                    $message = "Can't change $descriptor $field: can't change from '$orig_value' to '$new_value' ($caller_simple)";
                }
            }
        }
        else {
            $message = "Can't change $descriptor $field: unrecognized old $field '$orig_value' ($caller_simple)";
        }
    }

    $check = 0 unless $message eq '';

    return ($check, $message);
}

#
#
#
sub _change_value_with_trigger {
    my $self      = shift;
    my $new_value = shift;
    my $args      = { @_ };

    my @caller = caller(1);
    my $caller_simple = sprintf '%s line %s', @caller[1,2];

    my $field = delete $args->{_field};
    unless (defined $field) {
        IC::Exception->throw( qq{Can't change value missing argument: _field ($caller_simple)} );
    }
    unless (defined $new_value) {
        IC::Exception->throw( qq{Can't change $field missing argument: new value ($caller_simple)} );
    }

    #warn sprintf "_change_value_with_trigger: $self, $field, %s, $new_value ($caller_simple)\n", $self->$field;

    my $get_trigger_structure_method = delete $args->{_get_trigger_structure_method};
    unless (defined $get_trigger_structure_method) {
        IC::Exception->throw( qq{Can't change $field missing argument: _get_trigger_structure_method ($caller_simple)} );
    }

    $args->{no_logging} ||= 0;

    my $has_created_by  = $self->meta->column('created_by') ? 1 : 0;
    my $has_modified_by = $self->meta->column('modified_by') ? 1 : 0;

    my %common;
    if ($has_created_by and (defined $args->{created_by} || defined $args->{modified_by})) {
        $common{created_by} = $args->{created_by} // $args->{modified_by};
    }
    if ($has_modified_by and defined $args->{modified_by}) {
        $common{modified_by} = $args->{modified_by};
    }

    #
    # this needs to be atomic so start a transaction if we aren't already in one,
    # Rose::DB returns -1 when already in a transaction
    #
    my $already_in_txn = $self->db->begin_work;

    my $content = '';
    if (UNIVERSAL::can($self, 'log_actions') and ! $args->{no_logging}) {
        if (defined $args->{content} and $args->{content} ne '') {
            $content = $args->{content};
        }

        my @additional_details = ();
        if (defined $args->{addtl_details}) {
            unless (ref $args->{addtl_details} eq 'ARRAY') {
                IC::Exception->throw("Can't change status, invalid addtl details argument: $args->{addtl_details} (not an ARRAY ref) ($caller_simple)");
            }

            for my $element (@additional_details) {
                unless (ref $element eq 'HASH') {
                    IC::Exception->throw("Can't change status, invalid addtl detail element: $element (not a HASH ref) ($caller_simple)");
                }
                for my $key qw( ref_code value ) {
                    unless (defined $element->{$key} and $element->{$key} ne '') {
                        IC::Exception->throw("Can't change status, invalid addtl detail, missing key/value: $key ($caller_simple)");
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
                        %common,
                    },
                    {   
                        ref_code => 'to',
                        value    => $new_value,
                        %common,
                    },
                    @additional_details,
                ],
                %common,
            },
        );
    }

    my $orig_value = $self->$field;
    $self->$field($new_value);
    if ($has_modified_by && defined $args->{modified_by}) {
        $self->modified_by($has_modified_by);
    }
    $self->save;

    my $return;
    if ($self->can($get_trigger_structure_method)) {
        my $change_struct = $self->$get_trigger_structure_method;
        my $descriptor    = $self->_mixin_model_descriptor;

        if (exists $change_struct->{$field}) {
            $change_struct = $change_struct->{$field};
        }

        # must handle all transitions even if handling is a no-op
        if (exists $change_struct->{$orig_value}) {
            if (exists $change_struct->{$orig_value}->{$new_value}) {
                my $sub_ref = $change_struct->{$orig_value}->{$new_value};

                my @call_args = ($self, _orig_value => $orig_value, _new_value => $new_value, %$args);
                if (ref $sub_ref eq 'CODE') {
                    $return = $sub_ref->(@call_args);
                }
                elsif (ref $sub_ref eq 'HASH' and ref $sub_ref->{do} eq 'CODE') {
                    $return = $sub_ref->{do}->(@call_args);
                }
                else {
                    IC::Exception->throw("Can't change $descriptor $field: $orig_value to $new_value not a subroutine ($caller_simple)");
                }
            }
            else {
                IC::Exception->throw("Can't change $descriptor $field: can't change from '$orig_value' to '$new_value' ($content) ($caller_simple)");
            }
        }
        else {
            IC::Exception->throw("Can't change $descriptor $field: unrecognized old $field '$orig_value' ($content) ($caller_simple)");
        }
    }

    unless ($already_in_txn == -1) {
        $self->db->commit;
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
