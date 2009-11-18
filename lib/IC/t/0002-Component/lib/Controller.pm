package Controller;

use strict;
use warnings;

use IC::Controller ();
use Moose;
extends qw(IC::Controller);
has attribute => (is => 'rw',);

__PACKAGE__->registered_name('controller');
1;

package Controller2;

use strict;
use warnings;

use Moose;
extends qw(Controller);
__PACKAGE__->registered_name('controller2');
1;

package Controller3;

use strict;
use warnings;

use Moose;
extends qw(Controller);
__PACKAGE__->registered_name('controller3');
1;

package ControllerNoViews;

use strict;
use warnings;

use Moose;
extends qw(Controller);
__PACKAGE__->registered_name('no_views');
1;
