#Apache/Hello.pm
package Apache::Hello;

use strict;
use Apache::Constants ':common';

sub handler {
    my $r = shift; 

    my $ua = $r->header_in('User-Agent'); 

    $r->header_out("Perl-Version" => $]); 

    $r->content_type("text/html"); 

    $r->send_http_header;

    $r->print("Hello, I see you see me with $ua.");

    return OK;
}

1;

__END__

=head1 NAME

Apache::Hello - Apache/Perl Hello World module

=head1 SYNOPSIS

 #httpd.conf
 <Location /hello>
 SetHandler perl-script

 PerlHandler Apache::Hello
 </Location>

=head1 DESCRIPTION

A simple "Hello World" module, used as an example at the 
1st ORA Perl conference talk on Apache/Perl.

=head1 SEE ALSO

mod_perl(3), Apache(3)

=head1 AUTHOR

Doug MacEachern
