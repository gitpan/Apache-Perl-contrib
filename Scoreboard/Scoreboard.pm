package Apache::Scoreboard;

use DynaLoader ();
use vars qw(@ISA);
@ISA = qw(DynaLoader);

bootstrap Apache::Scoreboard;

my(@status) = qw{
    SERVER_DEAD 
    SERVER_READY
    SERVER_STARTING
    SERVER_BUSY_READ
    SERVER_BUSY_WRITE
    SERVER_BUSY_KEEPALIVE
    SERVER_BUSY_LOG
    SERVER_BUSY_DNS
    };

my(@status_strings) = qw(. _ S R W K L D);

@Status{@status} = @status_strings;

sub status_str {
    my($self) = @_; 
    $status_strings[$self->status];
}

sub status { shift->{status} }
sub pid { shift->{pid} }

1;

__END__

