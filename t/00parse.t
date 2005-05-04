use Test::More tests => 6;

use Logfile::EPrints;
ok(1);

my $logline = '68.239.101.251 - - [06/Mar/2005:04:29:35 +0000] "GET /9271/01/Microsoft_Word_-_RemiseSenApp031_-_Sensors_and_their_applications_2003_Lime\\xe2\\x80\\xa6.pdf HTTP/1.1" 200 38896 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.0.3705)"';
my $hit = Logfile::Hit::Combined->new($logline);
ok($hit);
ok($hit->address eq '68.239.101.251');
ok($hit->code eq '200');

use Logfile::Institution;
use Logfile::Repeated;
ok(1);

open my $fh, 'examples/ecs.log' or die $!;

my $parser = Logfile::EPrints->new(
	identifier=>'oai:eprints.ecs.soton.ac.uk:',
	handler=>Logfile::Institution->new(
		handler=>Logfile::Repeated->new(
			handler=>Handler->new(),
	)),
);
$parser->parse_file($fh);
ok(1);

package Handler;

use vars qw( $AUTOLOAD );

sub new { bless {}, shift }

sub fulltext {
	my ($self,$hit) = @_;
#	warn $hit->homepage." => ".$hit->institution."\n" if $hit->homepage;
#	warn "fulltext: " . $hit->country . "/" . $hit->identifier . "/" . $hit->datetime . "\n";
}

sub repeated {
	my ($self,$hit) = @_;
#	warn sprintf("repeated: %s/%s/%s", $hit->identifier, $hit->address, $hit->datetime);
}

sub abstract {
	my ($self,$hit) = @_;
#	warn "abstract: " . $hit->country . "/" . $hit->identifier . "\n";
}

sub browse {
	my ($self,$hit) = @_;
#	warn "browse: " . $hit->section . "\n";
}

sub search {
	my ($self,$hit) = @_;
	my $uri = URI->new($hit->path,'http');
#	warn "search: " . join(',',$uri->query_form) . "\n";
}

sub DESTROY {}

sub AUTOLOAD {
	my $self = shift;
	$AUTOLOAD =~ s/^.*:://;
	warn "$AUTOLOAD\n";
}
