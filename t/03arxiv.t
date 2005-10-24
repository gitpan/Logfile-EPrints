use Test::More tests => 11;

use Logfile::EPrints;
ok(1);

my $logline = 'hal9032.cs.uiuc.edu - - [03/Jul/2005:07:10:09 +0100] "GET /robots.txt" HTTP/1.0" 200 889 "-" ""Mozilla/5.0 (X11; U; Linux i686;en-US; rv:1.2.1) Gecko/20030225""';
my $hit = Logfile::Hit::arXiv->new($logline);
ok($hit);
ok($hit->hostname eq 'hal9032.cs.uiuc.edu');
ok($hit->code eq '200');
ok($hit->datetime eq '20050703071009');
ok($hit->page eq '/robots.txt');

$logline = 'bigbird-l1.webworksgy.com - - [27/Aug/2005:04:00:32 +0100] [Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.8) Gecko/20050511 Firefox/1.0.4|-|0|http://uk.arxiv.org/abs/nlin.AO/0411066] "GET /pdf/nlin.AO/0411066 HTTP/1.0" 302 238';
$hit = Logfile::Hit::Bracket->new($logline);
ok($hit);
ok($hit->hostname eq 'bigbird-l1.webworksgy.com');
ok($hit->page eq '/pdf/nlin.AO/0411066');
ok($hit->code == 302);

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
