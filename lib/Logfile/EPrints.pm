package Logfile::EPrints;

use strict;
use warnings;

use Logfile::Hit;
use Logfile::Institution;
use Logfile::Repeated;
use Logfile::Parser;
use Logfile::RobotsTxtFilter;

use URI;
use Socket;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use vars qw( %UID %ROBOTS );

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EPrints::ParseLog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.01';

# Preloaded methods go here.

sub new {
	my ($class,%args) = @_;
	my $self = bless \%args, $class;
	$self;
}

sub hit {
	my ($self,$hit) = @_;
	if( 'GET' eq $hit->method && 200 == $hit->code ) {
		my $path = URI->new($hit->page,'http')->path;
		# Full text
		if( $path =~ /^\/(\d+)\/\d/ ) {
			$hit->{identifier} = $self->_identifier($1);
			$self->{handler}->fulltext($hit);
		} elsif( $path =~ /^\/(\d+)\/?$/ ) {
			$hit->{identifier} = $self->_identifier($1);
			$self->{handler}->abstract($hit);
		} elsif( $path =~ /^\/view\/(\w+)\// ) {
			$hit->{section} = $1;
			$self->{handler}->browse($hit);
		} elsif( $path =~ /^\/perl\/search/ ) {
			$self->{handler}->search($hit);
		} else {
			#warn "Unknown path = ", $uri->path, "\n";
		}
	}
}

sub _identifier {
	my ($self,$no) = @_;
	return ($self->{'identifier'}||'oai:GenericEprints:').$no;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Logfile::EPrints - Parse Apache logs from GNU EPrints

=head1 SYNOPSIS

  use Logfile::EPrints;

  my $parser = Logfile::Parser->new(
	handler=>Logfile::EPrints->new(
	  identifier=>'oai:myir:', # Prepended to the eprint id
  	  handler=>Logfile::Repeated->new(
	    handler=>Logfile::Institution->new(
	  	  handler=>$MyHandler,
	  )),
	),
  );
  open my $fh, "<access_log" or die $!;
  $parser->parse_file($fh);

  package MyHandler;

  sub new { ... }
  sub AUTOLOAD { ... }
  sub fulltext {
  	my ($self,$hit) = @_;
	printf("%s from %s requested %s (%s)\n",
	  $hit->hostname||$hit->address,
	  $hit->institution||'Unknown',
	  $hit->page,
	  $hit->identifier,
	);
  }

=head1 DESCRIPTION

The Logfile::* modules provide a means to analyze log files from Web servers (typically Institutional Repositories) by translating HTTP requests into more informative data, e.g. a full-text download by a user at Caltech.

The architectural design consists of a series of pluggable filters that read from a log file or stream into Perl objects/callbacks. The first filter in the stream needs to convert from the log file format into a Perl object representing a single "hit". Subsequent filters can then ignore hits (e.g. from robots) and/or augment them with additional data (e.g. country of origin by GeoIP).

=head1 CALLBACKS

See Logfile::Hit for the fields available from the 'hit' object.

=head2 Filter Callbacks

=over 4

=item abstract($handler,$hit)

=item browse($handler,$hit)

=item fulltext($handler,$hit)

=item repeated($handler,$hit)

Repeated is implemented by Logfile::Repeated

=item search($handler,$hit)

=back

=head1 SEE ALSO

=head1 AUTHOR

Timothy D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 TODO

Robots filter:

=item Exclude users that request robots.txt (probably requires persistent storage)
=item Exclude users by user-agent string

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Timothy D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
