package Model::Rose::Base;

use strict;
use warnings;

use Model::Rose::DB;
use Model::Rose::Object;
use Model::Cow;
use Model::Pattern;
use Model::MilkQuality;
use Model::CowMilkQuality;

# Clear this after the initial loading so IC doesn't maintain a broken
# handle in memory.
Model::Rose::DB->clear_singleton();

1;

__END__
