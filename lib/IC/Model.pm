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

=cut

