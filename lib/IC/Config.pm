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

__END__

=pod

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see: http://www.gnu.org/licenses/ 

=cut
