package Logfile::EPrints::arXiv;

use strict;
use warnings;

use URI;
use Socket;

require Exporter;
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

# Preloaded methods go here.

sub new {
	my ($class,%args) = @_;
	bless \%args, $class;
}

sub hit {
	my ($self,$hit) = @_;
warn "Error parsing: $hit" if( !defined($hit->code) or $hit->code =~ /\D/ );
	if( 'GET' eq $hit->method && 200 == $hit->code ) {
		my $path = URI->new($hit->page,'http')->path;
		$path =~ s/\/other//;
		if( $path =~ /^\/((PS_cache)|(ftp))/ ) {
			$path =~ s/\/\w+\/\d{4}\//\//;
		}
		if( $path =~ /^\/(abs|pdf|ps|PS_cache|dvi|ftp)\/([A-Za-z\-\.]+)\/?(\d{7})/ ) {
			my ($t,$i,$n) = ($1,$2,$3);
			$i=~ s/(?<=\w)\.\w+$//;
			$hit->{identifier} = 'oai:arXiv.org:'.$i.'/'.$n;
			if( $t eq 'abs' ) {
				$self->{handler}->abstract($hit);
			} else {
				$self->{handler}->fulltext($hit);
			}
		} elsif( $path =~ /^\/list/ ) {
			$self->{handler}->browse($hit);
		} elsif( $path =~ /^\/find/ ) {
			$self->{handler}->search($hit);
		# Index / Image requests / help
		# Other requests:
		# \/ = index
		# ^\/icon|uk\.gif = images
		# ^\/help = help pages
		# ^\/form = browsing form
		#} elsif( $path eq '/' || $path =~ /^\/(icon|help|form)|uk\.gif|robots.txt/) {
		} else {
			#warn "Unhandled request type: $path";
		}
	}
}

sub page2oai {
	my $page = shift;
	if( $page =~ /([A-Za-z\-\.]+\/\d{7})/ ) {
		my $identifier = $1;
		$identifier =~ s/(\w+)\.\w+/$1/;
		return 'oai:arXiv.org:'.$identifier;
	}
	return undef;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Logfile::EPrints::arXiv - Parse Apache logs from an arXiv mirror

=head1 SYNOPSIS

  use Logfile::EPrints::arXiv;

  my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints::arXiv->new(
  	  handler=>Logfile::EPrints::Repeated->new(
	    handler=>Logfile::EPrints::Institution->new(
	  	  handler=>$MyHandler,
	  )),
	),
  );
  open my $fh, "<access_log" or die $!;
  $parser->parse_fh($fh);
  close($fh);

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

See Logfile::EPrints.

=head1 HANDLER CALLBACKS

=over 4

=item abstract()

=item browse()

=item fulltext()

=item search()

=back

=head1 SEE ALSO

=head1 AUTHOR

Timothy D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Timothy D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
