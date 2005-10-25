package Logfile::EPrints::RobotsFilter;

use Carp;

carp "Logfile::EPrints::RobotsFilter doesn't do anything, this is just a placeholder\n";

use vars qw( $AUTOLOAD );

sub new
{
	my ($class,%args) = @_;
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	shift->{handler}->$AUTOLOAD(@_);
}

1;
