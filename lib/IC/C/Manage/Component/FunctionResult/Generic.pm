package IC::C::Manage::Component::FunctionResult::Generic;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::C::Manage::Component::FunctionResult';

class_has '+_kind' => ( default => 'generic' );
has '+view'        => ( default => 'manage/function/generic' );

no Moose;

1;

__END__
