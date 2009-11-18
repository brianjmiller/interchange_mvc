objects: <%= join(', ', map { "$_ => " . $objects->{$_}->value } sort { $a <=> $b } keys %{ $objects || {} } ) %>
