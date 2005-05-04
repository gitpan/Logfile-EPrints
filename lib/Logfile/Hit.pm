package Logfile::Hit::Combined;

# Log file format is:
# ADDRESS IDENTD_USERID USER_ID [DATE TIMEZONE] "request" HTTP_CODE RESPONSE_SIZE "referrer" "agent"

=pod

=head1 NAME

Logfile::Hit::Combined - Parse combined logs like those generated from Apache

=head1 SYNOPSIS

	use Logfile::Hit;

	my $hit = Logfile::Hit::Combined->new($line);

	printf("%s requested %s\n",
		$hit->hostname,
		$hit->page);

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
use vars qw( $AUTOLOAD %INST_CACHE $UA $LINE_PARSER @FIELDS $GEO );
use Text::CSV_XS;
use Socket;
use Geo::IP::PurePerl;
$LINE_PARSER = Text::CSV_XS->new({
	escape_char => '\\',
	sep_char => ' ',
});
$GEO = Geo::IP::PurePerl->new(GEOIP_STANDARD);

# !!! date is handled separately !!!
@FIELDS = qw(
	address userid_identd userid 
	request code size referrer agent
);

sub new {
	my $class = shift;
	my %self;

	my $str = shift || return;
	# The date is contained in square-brackets
	if( $str =~ s/\[([^\]]+)\]\s// ) {
		$self{date} = $1;
	}
	# Change apache escaping back to URI escaping
	$str =~ s/\\x/\%/g;
	
	# Split the log file fields
	if($LINE_PARSER->parse($str)) {
		@self{@FIELDS} = $LINE_PARSER->fields;
	} else {
		warn "Text::CSV_XS couldn't parse: " . $LINE_PARSER->error_input;
		return;
	}

	# Split the request
	@self{qw(method page version)} = split / /, $self{'request'};
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = $self{'address'};
		my( $name, $aliases, $addrtype, $length, @addrs ) = gethostbyname($self{'address'});
		$self{'address'} = inet_ntoa($addrs[0]) if defined($addrs[0]);
	}
	# Get the estimated country of origin by IP
	$self{country} = $GEO->country_code_by_addr($self{'address'});
			
	return bless \%self, $class;
}

sub AUTOLOAD {
	my $self = shift;
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	return ref($self->{$AUTOLOAD}) ?
		&{$self->{$AUTOLOAD}}($self,@_) : 
		$self->{$AUTOLOAD};
}

sub hostname
{
	my $self = shift;
	return $self->{hostname} if $self->{hostname};
	return $self->{hostname} = gethostbyaddr(inet_aton($self->address), AF_INET);
}

1;
