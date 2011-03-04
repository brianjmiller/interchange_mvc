package IC::Model::Rose::DB;

use strict;
use warnings;

use IC::Config;

use Rose::DB;
use base qw( Rose::DB );

use Rose::Object::MakeMethods::Generic (
    array => [
        'commit_callbacks'       => { interface => 'get_set_inited', hash_key => 'commit_callbacks' },
        'clear_commit_callbacks' => { interface => 'clear', hash_key => 'commit_callbacks' },
        'reset_commit_callbacks' => { interface => 'reset', hash_key => 'commit_callbacks' },
        '_push_commit_callbacks' => { interface => 'push', hash_key => 'commit_callbacks' },
    ], 
);

IC::Config->initialize;

if (defined IC::Config->smart_variable('SQLDSN')) {
    #warn "Registering db: " . IC::Config->smart_variable('SQLDSN') . "\n";
    __PACKAGE__->standard_base_configuration;
    __PACKAGE__->register_db(
        username        => IC::Config->smart_variable( 'SQLUSER' ),
        password        => IC::Config->smart_variable( 'SQLPASS' ),
        dsn             => IC::Config->smart_variable( 'SQLDSN'  ),
        connect_options => {
            AutoCommit        => 1,
            RaiseError        => 1,
            pg_enable_utf8    => 1,
        },
    );
}

sub add_commit_callbacks {
    my $self = shift;

    die "Database handle must be in a transaction in order to add commit callbacks.\n"
        unless $self->in_transaction;

    return $self->_push_commit_callbacks(@_);
}

sub begin_work {
    my $self = shift;

    $self->clear_commit_callbacks;

    return $self->SUPER::begin_work(@_);
}

sub commit {
    my $self = shift;

    my $result = $self->SUPER::commit(@_);
    $self->process_commit_callbacks if $result;

    return $result;
}

sub rollback {
    my $self = shift;

    $self->clear_commit_callbacks;

    return $self->SUPER::rollback(@_);
}

sub process_commit_callbacks {
    my $self = shift;

    my $count = 0;
    ++$count && $_->() for $self->commit_callbacks;

    $self->clear_commit_callbacks;

    return $count;
}

sub standard_base_configuration {
    my $invocant = shift;
    die 'standard_base_configuration() only available as a package method!'
        if ref $invocant
    ;
    $invocant->use_private_registry;
    $invocant->default_domain('production');
    $invocant->default_type('main');
    return;
}

# override register_db to enforce common defaults for site (domain, type, driver)
sub register_db {
    my $invocant = shift;
    my %params = @_;

    my %defaults = qw(
        domain      production
        type        main
        driver      pg
    );
    for my $default (keys %defaults) {
        $params{$default} = $defaults{$default}
            if ! defined $params{$default}
        ;
    }

    return $invocant->SUPER::register_db( %params );
}

#
# We're using a lexical variable to hold the first instance created,
# such that this package and any subclass packages can each get a singleton
# handle by default, stored in %singleton_repository keyed by the package name.
# Each class MUST provide one and only one domain/type handle or this system
# breaks down.
#

my %singleton_repository;

sub new {
    my $invocant = shift;
    my %args = @_;
    if (! delete $args{override_singleton}) {
        my $class = ref($invocant) || $invocant;
        $singleton_repository{$class} ||= $invocant->SUPER::new( %args );
        return $singleton_repository{$class};
    }
    else {
        return $invocant->SUPER::new( %args );
    }  
}

sub clear_singleton {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
	delete $singleton_repository{$class};
	return;
}

1;

__END__

=pod

=head1 NAME

B<IC::Model::Rose::DB> -- B<Rose::DB> derivative

=head1 SYNOPSIS

This class works basically like any other B<Rose::DB> class,
though it configures the registry and gets Rose/DBI
talking to the proper database based on your configuration
based on settings derived from B<IC::Config>.

The special behaviors:

=over

=item *

By default, the constructor returns a singleton connection.  This ensures that the same handle gets used throughout a request.  See below for details.

=item *

A "commit callback" feature lets you register callbacks to invoke upon successful commit of the current transaction.

=back

=head1 CONSTRUCTOR

By default, B<new()> will return a singleton instance of
B<IC::Model::Rose::DB>, which ensures that database handle
overhead is minimized.

However, if you want an independent handle, you can provide
a Perly-true value for I<override_singleton>.

 use IC::Model::Rose::DB;
 my $db_a = IC::Model::Rose::DB->new;
 my $db_b = IC::Model::Rose::DB->new;
 my $db_c = IC::Model::Rose::DB->new(override_singleton => 1);
 # $db_a and $db_b are the same; $db_c is unique.

=head1 CALLBACKS

When the handle is within a transaction (a transaction
managed by the B<IC::Model::Rose::DB> object interface,
not by the underlying DBI handle interface), you can
register anonymous callback subs.  They will be invoked in
order of registration upon successful commit of the
current transaction.

This allows for things like cache rebuilds and such to
wait until commit success, while still being tied to
event-driven cache-on-write strategies.

The interface involved:

=over

=item I<commit_callbacks( [ ARRAYREF | subref1, subref2, ... ] )>

Get/set method for the commit callbacks queue on the current object.  Returns the queue contents in list context,
or the actual array reference in scalar context.

You can invoke this as a setter, in which case you may pass
an arrayref of subrefs, or a list of subrefs.

It is recommended that you not invoke as a setter directly,
and instead affect the stack via I<add_commit_callbacks()>.

The queue should be empty between transactions.  You
could set it outside a transaction, but it will be cleared
upon beginning the next transaction.

Additionally, after rollback or commit, the queue is
cleared.

=item I<clear_commit_callbacks()>

Empties the callback list.

=item I<add_commit_callbacks( CODEREF1, CODEREF2, ... )>

Given a list of subrefs as input, appends those subrefs
in order onto the callback queue.

This will throw an exception if invoked outsid the context of a transaction.

Use of this method is encouraged over direct setting,
as it allows for encapsulated, isolated code paths to
affect the callback queue.

=back

=head1 BLAME

Mostly me, but probably some of him, too.

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
