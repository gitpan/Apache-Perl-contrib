

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Time::localtime;

$VERSION = join '', localtime->mon()+1,  localtime->mday, localtime->year;
$VERSION =~ s/^/0/ unless length $VERSION == 6;

WriteMakefile(
    NORECURS => 1,
    'NAME'	=> 'mod_perl-contrib',
    'VERSION'   => $VERSION,
    'dist'    => {COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
 	          POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
    },
);
