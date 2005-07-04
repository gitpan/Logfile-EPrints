package Logfile::Parser;

use Logfile::Hit;
use POSIX qw/strftime/;

sub new
{
	my ($class,%args) = @_;
	$args{type} ||= $args{parser};
	$args{type} ||= 'Logfile::Hit::Combined';
	bless \%args, $class;
}

sub parse_fh
{
	my ($self,$fh) = @_;
	return unless my $handler = $self->{handler};

	while(<$fh>)
	{
		my $hit;
		unless( $hit = $self->{type}->new($_) ) {
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

	$p = Logfile::Parser->new(
	  type=>'Logfile::Hit::Combined',
	  handler=>$Handler
	);

	open my $fh, "<access_log" or die $!;
	$p->parse_fh($fh);
	close($fh);

=head1 METHODS

=over 4

=item new()

Create a new Logfile::Parser object with the following options:

	type - Optionally specify a class to parse log file lines with (defaults to ::CombinedLog)
	handler - Handler to call (see HANDLER CALLBACKS)

=back
	
=head1 HANDLER CALLBACKS

=over 4

=item hit()

=back

=cut
