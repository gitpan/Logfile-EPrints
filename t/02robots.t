use Test::More tests => 2;

use Logfile::EPrints;
ok(1);

open my $fh, "<examples/ecs.log" or die $!;
my $p = Logfile::Parser->new(
	handler=>Logfile::RobotsTxtFilter->new(
		handler=>Handler->new()
	)
);
$p->parse_fh($fh);
close($fh);
ok(1);

package Handler;

sub new { bless {prev=>time,c=>0}, shift }

sub DESTROY {}
sub AUTOLOAD {
	my $self = shift;
	$self->{c}++;
	if( $self->{prev} != time ) {
		print STDERR $self->{c}, "\r";
		$self->{c} = 0;
		$self->{prev} = time;
	}
}

1;
