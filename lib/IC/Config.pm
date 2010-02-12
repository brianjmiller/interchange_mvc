package IC::Config;

use strict;
use warnings;

use lib '/home/camp/lib';

use Camp::Config no_init => 1;
use base qw( Camp::Config );

use User::pwent qw(getpwuid);
use File::Spec ();
use Cwd ();
use Interchange::Deployment;

sub adhoc_base_path {
	return Interchange::Deployment->base_path();
}

sub adhoc_ic_path {
	my $self = shift;

	return File::Spec->catfile( $self->adhoc_base_path, 'interchange' );
}

sub adhoc_htdocs_path {
	my $self = shift;

	return File::Spec->catfile( $self->adhoc_base_path, 'htdocs' );
}

sub _validate_adhoc_user {
    my $invocant = shift;

    my $obj = getpwuid($>);
	die sprintf(
		"Invalid user; must run as owner of base path, not %s\n",
		$obj->name
	) unless -o $invocant->_setting_get('base_path');
	
    $invocant->_setting_set('user', $obj);

    return $invocant->_setting_get('user');
}

1;
