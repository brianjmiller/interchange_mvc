package IC::C::Manage::Component::FunctionResult::ListPaginated;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::C::Manage::Component::FunctionResult';

class_has '+_kind' => ( default => 'list_paginated' );
has '+view'        => ( default => 'manage/function/list_paginated' );

no Moose;

1;

__END__
