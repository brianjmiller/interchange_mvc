package IC::Model;

use strict;
use warnings;

use Scalar::Util ();

use IC::Log::Logger;

sub find {
    my $invocant = shift;
    return $invocant->_find( @_ );
}

sub find_by_sql {
    my $invocant = shift;
    return $invocant->_find_by_sql( @_ );
}

sub count {
    my $invocant = shift;
    return $invocant->_count( @_ );
}

sub set {
    my $invocant = shift;
    return $invocant->_set( @_ );
}

sub remove {
    my $invocant = shift;
    return $invocant->_remove( @_ );
}

sub notify_observers {
    my $self = shift;
    my $class = Scalar::Util::blessed($self) || $self;

    my $count;
    ++$count && $_->update($self, @_) for $class->observers;

    return $count;
}

sub transaction_aware_notification {
    IC::Exception->throw('transaction_aware_notification() should be overridden by the implementation subclass');
}

sub save {
    IC::Exception->throw('save() should be overridden by the implementation subclass');
}

sub insert {
    IC::Exception->throw('insert() should be overridden by the implementation subclass');
}

sub delete {
    IC::Exception->throw('delete() should be overridden by the implementation subclass');
}

sub update {
    IC::Exception->throw('update() should be overridden by the implementation subclass');
}

#
#  manage_class() and its helper method _manage_class() calculate, cache
#  and return the name of the specific manage class associated with
#  this particular model class.  The logic is designed so if there is
#  a subclass with an odd pluralization or other abnormality, you can
#  override _manage_class() in the specific subclass to return the name
#  of the manage class to use explicitly.
#
#  manage_class() does a check for existence in @INC, and does a
#  runtime require on the class in question.  This makes it suitable
#  for use in the manage area, where it can make it easier to write
#  general code without knowing the specific manage classes of the
#  objects involved until runtime.
#
#  _manage_class() returns the name of the class only, and does not
#  perform any checks to see if the indicated class exists.  In
#  general, you will want to override _manage_class for specific M.pm
#  subclasses which do not follow the current conventions of Manage.pm
#  subclass naming.
#
{
    # local lexical cache so we don't need to calculate each time
    my %_manage_class_cache;

    sub manage_class {
        my $self = shift;
    
        my $class = ref $self || $self;
        return $_manage_class_cache{ $class } if defined $_manage_class_cache{ $class };

        my $manage_class = $self->_manage_class;
        if ($manage_class) {
            # check to see if the calculated class exists
            do {
                local $@;

                eval "require $manage_class";
                if ($@) {
                    warn "Failed to require manage class ($manage_class): $@";
                }
                else {
                    $_manage_class_cache{ $class } = $manage_class;
                }
            };
        }
        $_manage_class_cache{ $class } ||= undef;

        return $_manage_class_cache{ $class }; 
    }

    sub _manage_class {
        my $self = shift;
        my $class = ref $self || $self;

        if ( $class =~ s/^(.+)::M::// ) {
            my $prefix = $1;

            # simplistic pluralization algorithm - override for specific
            # exceptions
            $class = join '::', map {
                /y$/ ? s/y$/ies/ : # pluralize -y as -ies and skip the other checks
                /ss$/ ? s/$/es/  : # pluralize -ss as -sses and skip the other checks
                /us$/ ? s/$/es/  : # pluralize -us as -uses and skip the other checks
                !/s$/ && s/$/s/  ; # if we end in -s, don't pluralize, otherwise add an -s
                $_ 
            } split '::', $class;

            return $prefix . '::Manage::' . $class;
        }

        return '';
    }
}


1;

__END__

=pod

=head1 NAME

IC::Model -- base class for all model objects in MVC

=head1 DESCRIPTION

B<IC::Model> defines a basic interface that all model classes/objects
should support within the MVC system.  It is up to the base class of
any specific model family (like Rose::DB::Object, for example), to
subclass B<IC::Model> and provide implementations for the relevant
methods in order to make that model family work properly within the MVC
model space.

While at present B<IC::Model> merely provides a basic interface, subclassing
it means that it can be extended to provide generic tools like caching which
will magically become native to all model objects in the system.  Also, defining
a common interface for all models is no small thing; it reduces the learning
curve of the system in general.

=head1 METHODS

All methods at present merely pass through to the underlying model family
implementation.  There is no common set of parameters enforced for any of these
methods as of this writing; this means the particulars of the parameters are
entirely dependent on the underlying model family and its implementation.  Despite
this, the common interface should make for more readable code overall as the body
of model objects grows.

=over

=item B<find()>

Should return an arrayref of model objects based on whatever parameters are passed.

Depends on the underlying model family having a B<_find()> method to call.

=item B<find_by_sql()>

Should return an arrayref of model objects based on the SQL statement provided.

Depends on the underlying model family having a B<_find_by_sql()> method.

=item B<count()>

Returns the count of objects matching the critieria provided within the parameters.

Depends on the underlying model family implementing a B<_count()> method.

=item B<set()>

Updates the objects matching whatever parameters are provided.

Depends on the underlying model family implementing a B<_set()> method.

=item B<remove()>

Deletes any objects matching the parameters provided.

Depends on the underlying model family implementing a B<_remove()> method.

=item B<logger()>

Returns a logging object, defaulting to that in B<IC::Log>; see the
B<IC::Log::Logger> module for details, but know that the result should be
a derivative of B<IC::Log::Base>.

B<IC::Model> does not make assumptions about the object system, so it does
not provide an attribute for I<get/set_logger>.  This can be implemented in
lower-level subclasses of B<IC::Model> that hook into other object families.

=back

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

