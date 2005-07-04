package Logfile::RobotsTxtFilter;

use DB_File;

use constant BOT_CACHE => '/usr/local/share/Logfile/botcache.db';
use constant CACHE_TIMEOUT => 60*60*24*30; # 30 days
use vars qw( $AUTOLOAD );

sub new
{
	my ($class,%args) = @_;
	my $self = bless \%args, ref($class) || $class;
	tie %{$self->{cache}}, 'DB_File', ($args{'file'}||BOT_CACHE) 
		or die "Unable to open robots cache database (".($args{'file'}||BOT_CACHE)."): ".$!;
	my @KEYS;
	while( my ($key, $value) = each %{$self->{cache}} ) {
		my ($utime,$agent) = split / /, $value, 2;
		push @KEYS, $key if( $utime < time - CACHE_TIMEOUT );
	}
	delete $self->{cache}->{$_} for @KEYS;
	$self;
}

sub DESTROY
{
	my $self = shift;
	untie %{$self->{cache}};
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my ($self,$hit) = @_;
	if( $hit->page =~ /robots\.txt$/ ) {
		return $self->robotstxt($hit);
	}
	if( defined($self->{cache}->{$hit->address}) ) {
		#warn "Ignoring hit from " . $hit->address . " (" . $self->{cache}->{$hit->address} . ")";
	} else {
		return $self->{handler}->$AUTOLOAD($hit);
	}
}

sub robotstxt
{
	my ($self,$hit) = @_;
#	warn "Got new robot: " . join(',',$hit->hostname||$hit->address,$hit->utime,$hit->agent) . "\n";
	$self->{cache}->{$hit->address} = join ' ', $hit->utime, $hit->agent;
}

1;
