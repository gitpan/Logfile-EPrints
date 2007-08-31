package Logfile::EPrints;

use strict;
use warnings;

use Carp;
use URI;
use Socket;

# Deprecated namespace
use Logfile::EPrints::arXiv;

use Logfile::EPrints::Hit;
use Logfile::EPrints::Institution;
use Logfile::EPrints::Repeated;
use Logfile::EPrints::Parser;
use Logfile::EPrints::Parser::OAI;
use Logfile::EPrints::RobotsTxtFilter;
use Logfile::EPrints::Period;

use Logfile::EPrints::Mapping::arXiv;
use Logfile::EPrints::Mapping::DSpace;
use Logfile::EPrints::Mapping::EPrints;

# Maintain backwards compatibility
our @ISA = qw( Logfile::EPrints::Mapping::EPrints );

our $VERSION = '1.12';

1;

__END__

=head1 NAME

Logfile::EPrints - Parse Apache logs from GNU EPrints

=head1 SYNOPSIS

  use Logfile::EPrints;

  my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints::Mapping::EPrints->new(
	  identifier=>'oai:myir:', # Prepended to the eprint id
  	  handler=>Logfile::EPrints::Repeated->new(
	    handler=>Logfile::EPrints::Institution->new(
	  	  handler=>$MyHandler,
	  )),
	),
  );
  open my $fh, "<access_log" or die $!;
  $parser->parse_fh($fh);
  close $fh;

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

=head1 HANDLER CALLBACKS

Other Logfile::EPrints modules may supply additional callbacks.

=over 4

=item abstract()

=item fulltext()

=item browse()

=item search()

=back

=head1 SEE ALSO

L<Logfile::EPrints::Hit>, L<Logfile::EPrints::Mapping>.

=head1 AUTHOR

Timothy D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Timothy D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
