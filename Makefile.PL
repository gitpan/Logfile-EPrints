use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Logfile::EPrints',
    VERSION_FROM      => 'lib/Logfile/EPrints.pm', # finds $VERSION
    PREREQ_PM         => {
		Geo::IP::PurePerl => 0,
		Date::Parse => 0,
		LWP::UserAgent => 0,
		Socket => 0,
		URI => 0,
		Text::CSV_XS => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Logfile/EPrints.pm', # retrieve abstract from module
       AUTHOR         => 'Timothy D Brody <tdb01r@ecs.soton.ac.uk>') : ()),
);
