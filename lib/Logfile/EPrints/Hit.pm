package Logfile::EPrints::Hit;

=pod

Logfile::EPrints::Hit - Generic 'hit' object

=head1 DESCRIPTION

This object represents a single entry in a log file and doesn't proscribe any particular schema.

This uses the 'AUTOLOAD' mechanism to allow any variable to be defined as a method.

'Hit' objects are passed between filters that may add additional functionality (e.g. by subclassing the hit object).

=head1 SYNOPSIS

	use Logfile::EPrints::Hit;

	my $hit = Logfile::EPrints::Hit->new;
	$hit->date( '2006-05-01 23:10:05' );

	print $hit->date;

=cut

use strict;
use warnings;

use vars qw( $AUTOLOAD );

sub new
{
	my( $class, %args ) = @_;
	return bless \%args, ref($class) || $class;
}

sub AUTOLOAD {
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my $self = shift;
	return ref($self->{$AUTOLOAD}) ?
		&{$self->{$AUTOLOAD}}($self,@_) : 
		$self->{$AUTOLOAD};
}

package Logfile::EPrints::Hit::Combined;

# Log file format is:
# ADDRESS IDENTD_USERID USER_ID [DATE TIMEZONE] "request" HTTP_CODE RESPONSE_SIZE "referrer" "agent"

=pod

=head1 NAME

Logfile::EPrints::Hit::Combined - Parse combined logs like those generated from Apache

=head1 SYNOPSIS

	use Logfile::EPrints::Hit;

	my $hit = Logfile::EPrints::Hit::Combined->new($line);

	printf("%s requested %s\n",
		$hit->hostname,
		$hit->page);

=head1 CLASS METHODS

=over 4

=item Logfile::EPrints::Hit::Combined::initialise_geo_ip( [ FILENAME, [ FLAGS ] ] )

Initialise the GeoIP database with Maxmind country database located at FILENAME (must be called before trying to access country()). See L<Geo::IP> or L<Geo::IP::PurePerl>.

=cut

=back

=head1 METHODS

=over 4

=item address()

IP address (or hostname if IP address could not be found).

=item hostname()

Hostname (undef if the address is an IP without a reverse DNS entry).

=item date()

Apache formatted date/time.

=item datetime()

Date/time formatted as yyyymmddHHMMSS.

=item userid_identd()

=item identd()

=item request()

Request string.

=item code()

HTTP server code.

=item size()

HTTP server response size.

=item referrer()

User agent referrer.

=item agent()

User agent string.

=item method()

Request method (GET, HEAD etc.).

=item page()

Requested page - probably won't include the virtual host!

=item version()

HTTP version requested (HTTP/1.1 etc).

=item country()

Country that the IP is probably in (according to GeoIP).

=item homepage()

Home page of the requesting user's service provider, i.e. www.<hostname>. Performs an on-demand HTTP request.

=item institution()

Title of the user's home page. Performs an on-demand HTTP request, with the result cached by the class.

=back

=head1 AUTHOR

Tim Brody - <tdb01r@ecs.soton.ac.uk>

=cut

#use warnings;
#use strict;

use vars qw( @ISA );
@ISA = qw( Logfile::EPrints::Hit );

use vars qw( $AUTOLOAD %INST_CACHE $UA $LINE_PARSER @FIELDS $GEO );
use Date::Parse;
use POSIX qw/ strftime /;
use Text::CSV_XS;
use Socket;
#use overload '""' => \&toString;
$LINE_PARSER = Text::CSV_XS->new({
	escape_char => '\\',
	sep_char => ' ',
});

# !!! date is handled separately !!!
@FIELDS = qw(
	address userid_identd userid 
	request code size referrer agent
);

sub initialise_geo_ip
{
	my( $filename, $flags ) = @_;
	foreach my $class (qw( Geo::IP Geo::IP::PurePerl ))
	{
		eval "use $class";
		unless( $@ )
		{
			$GEO = @_ ? $class->open( @_ ) : $class->new();
			last;
		}
	}
	if( $GEO )
	{
		no warnings;
		*country = \&_country;
	}
	else
	{
		Carp::croak "Error loading GeoIP: make sure you have Geo::IP or Geo::IP::PurePerl installed";
	}
}

sub new {
	return unless $_[1];
	my %self = ('raw'=>$_[1]);

	# The date is contained in square-brackets
	if( $_[1] =~ s/\[([^\]]+)\]\s// ) {
		$self{date} = $1;
	}
	# Change apache escaping back to URI escaping
	$_[1] =~ s/\\x/\%/g;
	
	# Split the log file fields
	if($LINE_PARSER->parse($_[1])) {
		@self{@FIELDS} = $LINE_PARSER->fields;
	} else {
		warn "Text::CSV_XS couldn't parse: " . $LINE_PARSER->error_input;
		return;
	}

	# Split the request
	@self{qw(method page version)} = split / /, $self{'request'};
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = delete $self{'address'};
	}
			
	return bless \%self, $_[0];
}

sub toString {
	my $self = shift;
	my $str = "===Parsed Reference===\n";
	while(my ($k,$v) = each %$self) {
		$str .= "$k=".($v||'n/a')."\n";
	}
	$str;
}

sub _getipbyname
{
	my( $name, $aliases, $addrtype, $length, @addrs ) = gethostbyname($_[0]);
	return defined($addrs[0]) ? inet_ntoa($addrs[0]) : undef;
}

sub address
{
	$_[0]->{address} ||= _getipbyname( $_[0]->{hostname} ) || $_[0]->{hostname};
}

sub country
{
	initialise_geo_ip();
	return $_[0]->country;
}

# Get the estimated country of origin by IP
sub _country
{
	$_[0]->{country} ||= $GEO->country_code_by_addr($_[0]->address);
}

sub hostname
{
	$_[0]->{hostname} ||= gethostbyaddr(inet_aton($_[0]->address), AF_INET);
}

sub utime
{
	$_[0]->{'utime'} ||= Date::Parse::str2time($_[0]->{date});
}

sub datetime
{
	$_[0]->{datetime} ||= _time2datetime($_[0]->utime);
}

sub _time2datetime {
	strftime("%Y%m%d%H%M%S",localtime($_[0]));
}

package Logfile::EPrints::Hit::arXiv;

# Log file format is:
# ADDRESS IDENTD_USERID USER_ID [DATE TIMEZONE] "request" HTTP_CODE RESPONSE_SIZE "referrer" "agent"
# But can have unescaped quotes in the request or agent field (might be just uk mirror oddity)

use strict;
use warnings;

use Socket;
use vars qw( @ISA );
@ISA = qw( Logfile::EPrints::Hit::Combined );

sub new {
	my ($class,$hit) = @_;
	my (%self, $rest);
	$self{raw} = $hit;
	(@self{qw(address userid_identd userid)},$rest) = split / /, $hit, 4;
	$rest =~ s/^\[([^\]]+)\] //;
	$self{date} = $1;
	$rest =~ s/ (\d+) (\d+|-)(?= )//; # Chop code & size out of the middle
	@self{qw(code size)} = ($1,$2);
	$rest =~ s/^\"([A-Z]+) ([^ ]+) (HTTP\/1\.[01])\" //;
	@self{qw(method page version)} = ($1,$2,$3);
	
	# Apache replaces the % in URIs with \x
	$self{page} =~ s/\\x/\%/g;
	chop($self{page}) if substr($self{page},-1) eq '"';
	
	$rest =~ s/^\"([^\"]+)\" \"(.+)\"$//;
	@self{qw(referrer agent)} = ($1,$2);
	
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = delete $self{'address'};
	}

	bless \%self, $class;
}

package Logfile::EPrints::Hit::Bracket;

# Logfile format is:
#
# host ident user_id [dd/mmm/yyyy:hh:mm:ss +zone] [User Agent|email?|?|referrer] "page" code size

use strict;
use warnings;

use Socket;
use vars qw( @ISA );
@ISA = qw( Logfile::EPrints::Hit::Combined );

sub new {
	my( $class, $hit ) = @_;
	my %self = (raw => $hit);
	my $rest;

	(@self{qw(address userid_identd userid)},$rest) = split / /, $hit, 4;
	$self{date} = substr($rest,1,26);
	$rest = substr($rest,30);
	$rest =~ s/ "([A-Z]+) ([^ ]+) (HTTP\/1\.[01])" (\d+) (\d+|-)$//;
	@self{qw(method page version code size)} = ($1,$2,$3,$4,$5);
	chop($rest);
	@self{qw(agent from process_time referrer)} = split /\|/, $rest;
	
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = delete $self{'address'};
	}

	bless \%self, $class;
}

1;
