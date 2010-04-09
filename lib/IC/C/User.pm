=pod

This class should be subclassed by an app specific variant that will
do the registration of the controller name.

=cut
package IC::C::User;

use strict;
use warnings;

use Email::Valid;

use IC::Email;
use IC::M::User;

use Moose;
extends qw( IC::C );

has +layout => ( default => 'layouts/standard' );

no Moose;

my $current_preferred_hash_kind = 'sha1';

# the application subclass should register itself as the provider of the 'manage' controller
# and set up the anonymous actions (which require the registered name to already be set)
#__PACKAGE__->registered_name('user');
#__PACKAGE__->anonymous_actions(
    #qw(
        #login_form
        #login_auth
    #)
#);

sub menu {
    my $self = shift;

    $self->content_title('Account Menu');
    $self->render;

    return;
}

sub login_form {
    my $self = shift;
    return $self->_login_form;
}

sub login_auth {
    my $self = shift;
    my $params = $self->parameters;
    
    my $user = eval {
        IC::M::User->authenticate_credentials(
            username    => $params->{username},
            password    => $params->{password},
        );
    };
    return $self->_login_form($@) if $@;

    $self->_login($user);   

    return $self->_post_login_redirect;
}

sub logout {
    my $self = shift;

    $self->_logout;

    return $self->_post_login_redirect;
}

sub switch_user {
    my $self = shift;
    my $params = $self->parameters;

    my $user = IC::M::User->new( id => $params->{user_id} )->load;

    IC::Exception->throw('No right for switch_user to user ' . $user->id)
        unless $self->check_right('switch_user', $user);

    $self->_login($user);

    return $self->_post_login_redirect;
}

sub account_maintenance_form {
    my $self = shift;

    my $saved_form = delete $self->session->{_pre_populated_forms}->{'user/account_maintenance'};

    my $user = $self->user;

    my $f = {};
    for my $field qw( username email ) {
        my $value;
        if (defined $saved_form->{$field}) {
            $value = $saved_form->{$field};
        }
        else {
            $value = $user->$field;
        }
        $f->{$field} = $value;
    }

    $self->content_title('Account Maintenance');
    $self->render(
        context => {
            f => $f,
        },
    );

    return;
}

sub account_maintenance_save {
    my $self = shift;

    my $params = $self->parameters;

    my $save_form = $self->session->{_pre_populated_forms}->{'user/account_maintenance'} = {};
    for my $field qw( username email ) {
        $save_form->{$field} = $params->{$field};
    }

    eval {
        for my $field qw( username email ) {
            unless (defined $params->{$field} and $params->{$field} ne '') {
                IC::Exception::AccountMaintenanceMissingValue->throw("Required field missing: $field");
            }
        }
        my $email;
        if ($email = Email::Valid->address( $params->{email} )) {
            $params->{email} = $email;
        }
        else {
            IC::Exception->throw("Invalid e-mail address: $Email::Valid::Details");
        }

        my $user = $self->user;

        if (defined $params->{new_password} and $params->{new_password} ne '') {
            unless (defined $params->{con_password} and $params->{con_password} ne '') {
                IC::Exception::AccountMaintenanceMissingValue->throw('Unable to set new password: confirmation password not provided');
            }

            my $new_password = $params->{new_password};

            unless ($new_password eq $params->{con_password}) {
                IC::Exception::AccountMaintenancePasswordMismatch->throw('Unable to set new password: new and confirmation passwords do not match');
            }
            unless (length $new_password > 4) {
                IC::Exception::AccountMaintenancePasswordInvalid->throw('Unable to set new password: invalid password (length)');
            }
            if (lc $new_password eq lc $user->username) {         
                IC::Exception::AccountMaintenancePasswordInvalid->throw('Unable to set new password: invalid password (username match)');
            }

            my $new_password_hashed_test = IC::M::User->hash_password( $new_password, $user->password_hash_kind_code );
            if ($new_password_hashed_test eq $user->password) {
                IC::Exception::AccountMaintenancePasswordInvalid->throw('Unable to set new password: not changed (old password match)');
            }

            my $new_password_hashed_new;
            if ($user->password_hash_kind_code eq $current_preferred_hash_kind) {
                $new_password_hashed_new = $new_password_hashed_test;
            }
            else {
                $new_password_hashed_new = IC::M::User->hash_password( $new_password, $current_preferred_hash_kind );
            }

            $user->password( $new_password_hashed_new );
            $user->password_hash_kind_code( $current_preferred_hash_kind );
            $user->password_expires_on( undef );
        }

        my $old_email = $user->email;

        $user->username( $params->{username} );
        $user->email( $params->{email} );

        $user->save;

        #
        # beyond here updates have been made, they need to think that, so capture failures to send e-mails, etc.
        #

        eval {
            #
            # TODO: pull these from config, either in the DB or the config files
            #
            my $external_email_settings = {
                from    => 'IC Site',
                subject => 'Account Maintenance Change',
            };

            my @external_body;
            push @external_body, "An account maintenance request has been processed.\n\n";
            push @external_body, "If you did not make this request, please reply to this e-mail to let\n";
            push @external_body, "us know. Thank You.\n";
            push @external_body, "\n";
            push @external_body, "Username: " . $user->username . "\n";
            push @external_body, "E-mail Address: " . $user->email . "\n";
            push @external_body, "\n";
            push @external_body, '(Session: ' . $self->session->{id} . ', IP: ' . $self->session->{ohost} . ")\n";

            my $external_email = IC::Email->new(
                %$external_email_settings,
                body => \@external_body,
            );
            $external_email->send( $old_email );
        };
        if ($@) {
            warn "Failure to send e-mail during account maintenance change: $@\n";
        }

        #
        # TODO: set a message that can be seen, aka "Your account changes were saved."
        #
    };
    my $e;
    if (
        $e = Exception::Class->caught('IC::Exception::AccountMaintenanceMissingValue')
        or
        $e = Exception::Class->caught('IC::Exception::AccountMaintenancePasswordMismatch')
        or
        $e = Exception::Class->caught('IC::Exception::AccountMaintenancePasswordInvalid')
    ) {
        #
        # TODO: set an error message
        #
        $self->redirect(
            controller => 'user',
            action     => 'account_maintenance_form',
            secure     => 1,
        );

        return;
    }
    elsif ($e = Exception::Class->caught()) {
        ref $e ? $e->rethrow : die $e;
    }

    $self->redirect(
        controller => 'user',
        action     => 'menu',
        secure     => 1,
    );

    return;
}

sub _login_form {
    my ($self, $exception) = @_;

    $self->html_header_component->body_args('onload="document.getElementById(\'user_login_form\').username.focus();"');
    $self->content_title('Login Form');
    $self->content_subtitle('Unauthorized Use Prohibited - Access Logged');
    $self->add_error_messages($exception) if $exception;
    
    my $view = $self->registered_name . '/login_form';
    $self->add_stylesheet(
        kind => 'ic',
        path => $view . '.css',
    );

    $self->render( view => $view );
    $self->response->headers->status('403 Forbidden') if $exception;

    return;
}

sub _post_login_redirect {
    my $self = shift;
    my $params = $self->parameters;

    #
    # TODO: need to handle this better
    #

    $self->redirect(
        controller => 'user',
        action     => 'menu',
        secure     => 1,
    );

    return; 
}

sub _login {
    my ($self, $user) = @_;

    push @{ $self->session->{login_stack} ||= [] }, { user => $user->id };

    return $user;
}

sub _logout {
    my $self = shift;

    my $session = $self->session;
    return unless $session->{login_stack};

    pop @{ $session->{login_stack} };
    delete $session->{login_stack} unless @{ $session->{login_stack} };

    return 1;
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
