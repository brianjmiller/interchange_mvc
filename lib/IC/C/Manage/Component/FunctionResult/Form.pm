package IC::C::Manage::Component::FunctionResult::Form;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::C::Manage::Component::FunctionResult';

class_has '+_kind' => ( default => 'form' );
has '+view'        => ( default => 'manage/function/form' );

no Moose;

1;

__END__
