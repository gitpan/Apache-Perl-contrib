package Apache::Timeit;

use strict;
use Benchmark;
use Apache::Constants ':common';

my $begin;

sub handler {
    my $r = shift;

    $begin = Benchmark->new; 
    $r->push_handlers(PerlLogHandler => \&log);

    return OK;
}

sub log {
    my $r = shift;

    my $end = Benchmark->new; 

    warn sprintf "timing request for %s: %s\n",
    $r->uri, timestr(timediff($end,$begin));

    return OK;
}

1;

__END__

=head1 NAME

Apache::Timeit - Benchmark PerlHandlers

=head1 SYNOPSIS

 PerlFixupHandler Apache::Timeit

=head1 DESCRIPTION

Use B<PerlFixupHandler> and B<PerlLogHandler> and the 
B<Benchmark> module to time execution of B<PerlHandler> code.

=head1 SEE ALSO

mod_perl(3), Apache(3), Benchmark(3)

=head1 AUTHOR

Doug MacEachern



