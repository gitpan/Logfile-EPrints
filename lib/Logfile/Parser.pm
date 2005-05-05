package Logfile::Parser;

use Logfile::Hit;
use POSIX qw/strftime/;

sub new
{
	my ($class,%args) = @_;
	bless \%args, $class;
}

sub parse_fh
{
	my ($self,$fh) = @_;
	return unless my $handler = $self->{handler};

	while(<$fh>)
	{
		my $hit;
		unless( $hit = Logfile::Hit::Combined->new($_) ) {
			warn "Couldn't parse: $_";
			next;
		}
		$handler->hit($hit);
	}
}

1;

=pod

=head1 NAME

Logfile::Parser - Parse Web server logs that are formatted as one hit per line (e.g. Apache)

=head1 SYNOPSIS

	use Logfile::Parser;

	$p = Logfile::Parser->new(handler=>$Handler);

	open my $fh, "<access_log" or die $!;
	$p->parse_fh($fh);
	close($fh);

=cut
