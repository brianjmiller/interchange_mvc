objects: <%= join(', ', map { $_->value } @{ $objects || [] }) %>
