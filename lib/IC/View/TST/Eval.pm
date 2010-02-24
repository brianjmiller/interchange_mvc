package IC::View::TST::Eval;

use strict;
use warnings;

my $default_root = 0;
sub new {
    my($class, $root, $mask) = @_;
    my $obj = {};
    bless $obj, $class;
    $obj->{Root}  = "IC::View::TST::Eval".$default_root++;
    return $obj;
}

sub root {
    my $obj = shift;
    return $obj->{Root};
}

sub DESTROY {
    my ($obj, $action) = @_;
    my $pkg = $obj->root();
    my ($stem, $leaf);

    no strict 'refs';
    $pkg = "main::$pkg\::";	# expand to full symbol table name
    ($stem, $leaf) = $pkg =~ m/(.*::)(\w+::)$/;

    my $stem_symtab = *{$stem}{HASH};

    my $leaf_glob   = $stem_symtab->{$leaf};
    my $leaf_symtab = *{$leaf_glob}{HASH};
    %$leaf_symtab = ();

	delete $stem_symtab->{$leaf};
    1;
}

sub share_from {
    my $obj = shift;
    my $pkg = shift;
    my $vars = shift;

    my $root = $obj->root();
    croak("vars not an array ref") unless ref $vars eq 'ARRAY';
    no strict 'refs';
    # Check that 'from' package actually exists
    croak("Package \"$pkg\" does not exist")
    unless keys %{"$pkg\::"};
    my $arg;
    foreach $arg (@$vars) {
    # catch some $safe->share($var) errors:
    croak("'$arg' not a valid symbol table name")
        unless $arg =~ /^[\$\@%*&]?\w[\w:]*$/
            or $arg =~ /^\$\W$/;
    my ($var, $type);
    $type = $1 if ($var = $arg) =~ s/^(\W)//;
    # warn "share_from $pkg $type $var";
    *{$root."::$var"} = (!$type)       ? \&{$pkg."::$var"}
              : ($type eq '&') ? \&{$pkg."::$var"}
              : ($type eq '$') ? \${$pkg."::$var"}
              : ($type eq '@') ? \@{$pkg."::$var"}
              : ($type eq '%') ? \%{$pkg."::$var"}
              : ($type eq '*') ?  *{$pkg."::$var"}
              : croak(qq(Can't share "$type$var" of unknown type));
    }
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
