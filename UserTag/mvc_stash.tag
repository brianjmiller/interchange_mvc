UserTag mvc_stash               Order        name
UserTag mvc_stash               PosNumber    1
UserTag mvc_stash               addAttr
UserTag mvc_stash               Routine      <<EOR
sub {
	my ($var, $opt) = @_;
	my $value = $Vend::Interpolate::Stash->{$var};
	if ($opt->{filter}) {
		$value = filter_value($opt->{filter}, $value, $var);
	}
    return $value;
}
EOR
