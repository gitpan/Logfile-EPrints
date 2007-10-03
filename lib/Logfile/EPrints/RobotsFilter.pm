package Logfile::EPrints::RobotsFilter;

use strict;
use warnings;

use Carp;

use vars qw( $AUTOLOAD %KNOWN_AGENTS );

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
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	my( $self, $hit ) = @_;
	my $UserAgent = $hit->agent
		or return $self->{handler}->$AUTOLOAD($hit);
	if( exists $KNOWN_AGENTS{ $UserAgent } )
	{
		return $KNOWN_AGENTS{ $UserAgent } ?
			undef :
			$self->{handler}->$AUTOLOAD($hit);
	}
	for(@RobotsSearchIDOrder)
	{
		if( $UserAgent =~ /$_/ )
		{
			$KNOWN_AGENTS{ $UserAgent } = 1;
			return undef;
		}
	}
	$KNOWN_AGENTS{ $UserAgent } = 0;
	return $self->{handler}->$AUTOLOAD($hit);
}

1;
