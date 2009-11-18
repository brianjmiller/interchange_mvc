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
