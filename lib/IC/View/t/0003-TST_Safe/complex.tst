<%=

sub do_it {
    my ($struct, $indent) = @_;
    my ($output, $close_marker, @list);
    $output = '';
    $indent ||= '';
    if (ref($struct) eq 'HASH') {
        $output .= "{\n";
        $close_marker = '}';
        @list = map { "$indent  $_ => " . do_it($struct->{$_}, $indent . '  ') }
            sort { $a cmp $b }
            keys %$struct
        ;
    }
    elsif (ref($struct) eq 'ARRAY') {
        $output .= "[\n";
        $close_marker = ']';
        @list = map { "$indent  " . do_it($_, $indent . '  ') } @$struct;
    }
    elsif (ref($struct)) {
        $output .= $struct->value;
    }
    else {
        $output .= $struct;
    }

    if (@list) {
        $output .= join("\n", @list) . "\n$indent$close_marker";
    }
    return $output;
}

do_it( $objects );

%>
