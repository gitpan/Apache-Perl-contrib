
# Apache::HttpEquiv.pm
#
# written by Rob Hartill (robh@imdb.com)
# last modified 31 December 1996
# version 1.0

package Apache::HttpEquiv;
use Apache ();

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

sub handler {
    my $r = shift;
    
    return 0 if # don't scan the file if..
	!$r->is_main # a subrequest
	    || $r->content_type ne "text/html" # it isn't HTML
		|| !open(FILE, $r->filename); # we can't open it
    
    local($/) = "\n";
    while(<FILE>) {
	last if m#<BODY>|</HEAD>#i; # exit early if in BODY
	if (m#META-EQUIV="([^"]+)"\s+CONTENT="([^"]+)"#) {
	    $r->err_headers_out($1, $2);
	}
    }
    close(FILE);
    return 0;
}
1;
 
 __END__
 
=head1 NAME
 
Apache::HttpEquiv - Implements HTML B<META_EQUIV> tag parsing
 
=head1 SYNOPSIS
 
 (add to an Apache C<.conf> file)
 
 PerlModule Apache::HttpEquiv
 PerlFixupHandler Apache::HttpEquiv
 
=head1 DESCRIPTION
 
C<Apache::HttpEquiv> is a simple example of how to use the power of
B<mod_perl>
to customise your Apache server.
 
e.g.

 <HTML>
 <HEAD><TITLE>My Away Page</TITLE>
 <META-EQUIV="Expires" CONTENT="Wed, 31 Dec 1997 16:40:00 GMT">
 <META-EQUIV="Set-Cookie" CONTENT="open=sesame">
 </HTML>
 
will cause the following extra C<HTTP> headers to be sent:
 
 Expires: Wed, 31 Dec 1997 16:40:00 GMT
 Set-Cookie: open=sesame
 
=head1 CONFIGURATION
 
This module needs mod_perl to be compiled with B<PERL_FIXUP>.
 
When configuring mod_perl say: 
 
 perl Makefile.PL PERL_FIXUP=1
 
=head1 SEE ALSO
 
mod_perl, perl(1), Apache(3)
 
=head1 AUTHOR
 
Rob Hartill <robh@imdb.com>

