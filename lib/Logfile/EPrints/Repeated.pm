package Logfile::EPrints::Repeated;

use vars qw( %SEEN $SESSION_LEN $AUTOLOAD );

$SESSION_LEN = 60*60*24; # 1 Day

sub new
{
	my ($class,%args) = @_;
	bless \%args, ref($class) || $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	shift->{handler}->$AUTOLOAD(@_);
}

sub fulltext
{
	my ($self,$hit) = @_;
	$hit->utime; # Calculate the utime
	my $r;
	if( defined($SEEN{$hit->identifier}->{$hit->address}) &&
		($hit->{utime} - $SEEN{$hit->identifier}->{$hit->address}) <= $SESSION_LEN
	) {
		$r = $self->{handler}->repeated($hit);
	} else {
		$r = $self->{handler}->fulltext($hit);
	}
	$SEEN{$hit->identifier}->{$hit->address} = $hit->{utime};
	return $r;
}

1;

=pod

=head1 NAME

Logfile::EPrints::Repeated - Catch fulltext events and check for repeated requests

=head1 DESCRIPTION

This filter catches fulltext events and either forwards the fulltext event or, if the same identifier has been requested by the same address within 24 hours, create a repeated event.

=head1 TODO

Free memory by removing requests older than 24 hours.

=head1 HANDLER CALLBACKS

=over 4

=item repeated()

=back

=cut
