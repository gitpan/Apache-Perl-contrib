use Data::Dumper 'Dumper';

use ExtUtils::testlib;
use lib qw(../blib/arch ../blib/lib);
use Apache::Scoreboard ();
my $file = "/opt/www/apache/logs/apache_runtime_status";
my $img = Apache::Scoreboard->image($file);

#print Data::Dumper->Dump($img);

foreach (@$img) {
    printf "pid=$_->{pid} status=%s\n", $_->status_str;
}

