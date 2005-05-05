package Logfile::Institution;

use vars qw( $AUTOLOAD %INST_CACHE $UA );

use LWP::UserAgent;
$UA = LWP::UserAgent->new();
$UA->timeout(5);

sub new
{
	my ($class,%args) = @_;
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my ($self,$hit) = @_;
	@$hit{qw(institution homepage)} = (\&institution,\&homepage);
	$self->{handler}->$AUTOLOAD($hit);
}

sub institution
{
	my $self = shift;
	return $self->{_institution} if exists($self->{_institution});
	@$self{qw(_institution _homepage)} = addr2institution($self->hostname);
	$self->{_institution};
}

sub homepage
{
	my $self = shift;
	return $self->{_homepage} if exists($self->{_homepage});
	@$self{qw(_institution _homepage)} = addr2institution($self->hostname);
	$self->{_homepage};
}

sub addr2institution {
	my $addr = shift or return;

	# Get the domain name
	return unless $addr =~ /([^\.]+)\.([^\.]+)\.([^\.]+)$/;
	my $uri = 'http://www.' . ((length($3) > 2 || length($2) > 3) ?
		join('.', $2, $3) :
		join('.', $1, $2, $3));
	$uri .= '/';
	return ($INST_CACHE{$uri},$uri) if $INST_CACHE{$uri};
	return if exists($INST_CACHE{$uri});

	# Retrieve the home page
	my $r = $UA->get($uri);
	if( $r->is_error ) {
		warn "Error retrieving homepage ($uri): " . $r->message;
		$INST_CACHE{$uri} = undef;
		return;
	}

	return unless $r->content =~ /<\s*title[^>]*>([^<]+)<\s*\/\s*title\s*>/is;
	my $title = $1;
	$title =~ s/\r\n/ /sg;
	$title =~ s/^\s+//;
	$title =~ s/(?:\-)?\s+$//;
	return ($INST_CACHE{$uri} = $title,$uri);
}

1;
