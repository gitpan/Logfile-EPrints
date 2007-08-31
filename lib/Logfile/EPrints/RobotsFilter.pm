package Logfile::EPrints::RobotsFilter;

use strict;
use warnings;

use Carp;
use DB_File;

use vars qw( $AUTOLOAD );

my $path = '/var/www/awstats/lib';
if( not -e "$path/robots.pm" or not -e "$path/search_engines.pm" )
{
	Carp::croak("Requires awstats 6.5 (can not read search_engines.pm in [$path])");
}
do "$path/robots.pm";
do "$path/search_engines.pm";

our @RobotsSearchIDOrder = ();
{
	no strict "refs";
	for(qw( list1 list2 listgen ))
	{
		push @RobotsSearchIDOrder, @{"RobotsSearchIDOrder_$_"};
	}
}
$_ = qr/$_/i for @RobotsSearchIDOrder;

sub new
{
	my ($class,%args) = @_;
	$args{ TmpRobot } = {};
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my( $self, $hit ) = @_;
	my $UserAgent = $hit->agent
		or return $self->{handler}->$AUTOLOAD($hit);
	for(@RobotsSearchIDOrder)
	{
		if( $UserAgent =~ /$_/ )
		{
			$self->{ TmpRobot }->{ $UserAgent } = 1;
			return;
		}
	}
	$self->{ TmpRobot }->{ $UserAgent } = 0;
	return $self->{handler}->$AUTOLOAD($hit);
}

1;