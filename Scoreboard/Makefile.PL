use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME	=> "Apache::Scoreboard",
    VERSION => "0.01",
    INC => '-I../src -I../src/modules/perl -I../$(APACHE_SRC) -I../$(APACHE_SRC)/regex -I$(APACHE_SRC) -I$(APACHE_SRC)/regex',
);

