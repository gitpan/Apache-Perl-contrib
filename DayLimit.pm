package Apache::DayLimit;

use strict;
use Apache::Constants ':common';
use Time::localtime;

my @wday = qw(sunday monday tuesday wednesday thursday friday saturday);

sub handler {
    my $r = shift;
    return DECLINED unless my $requires = $r->dir_config("RequireWeekdays");

    my $day = localtime->wday;

    for my $wd ( split /[,\s]+/, $requires ) {
	return OK if lc $wd eq $wday[$day];
    }

    $r->log_reason("Access forbidden on weekday `$wday[$day]'", $r->uri);
    return FORBIDDEN;
}

1;
__END__

=head1 NAME

Apache::DayLimit - Limit access based on weekday

=head1 SYNOPSIS

 <Limit GET>
 PerlSetVar RequireWeekdays  monday,tuesday,wednesday
 PerlAccessHandler Apache::DayLimit
 satisfy any
 </Limit>

=head1 DESCRIPTION

Access to the given uri will only be allowed if the current weekday is
the B<RequireWeekdays> list.

=head1 SEE ALSO

mod_perl(3), Apache(3)

=head1 AUTHOR

Doug MacEachern


