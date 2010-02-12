package IC::C::Manage::Component::FunctionResult::DetailView;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
extends 'IC::C::Manage::Component::FunctionResult';

class_has '+_kind' => ( default => 'detail_view' );
has '+view'        => ( default => 'manage/function/detail_view' );

no Moose;

1;

__END__
