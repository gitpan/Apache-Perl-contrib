package Apache::ProxyPassThru;

use strict;
use LWP::UserAgent ();
use Apache::Constants ':common';

sub translate {
    my($r) = @_;
    return DECLINED unless $r->proxyreq;
    $r->handler("perl-script"); #ok, let's do it
    return OK;
}

sub handler {
    my($r) = @_;
    my($key,$val);

    my $request = new HTTP::Request $r->method, $r->uri;

    my(%headers_in) = $r->headers_in;
    while(($key,$val) = each %headers_in) {
	$request->header($key,$val);
    }

    my $res = (new LWP::UserAgent)->request($request);

    #feed reponse back into our request_rec*
    $r->status($res->code);
    $r->status_line(join " ", $res->code, $res->message);
    $res->scan(sub {
	$r->header_out(@_);
    });

    $r->send_http_header();
    $r->print($res->content);

    return OK;
}

1;

__END__

=head1 NAME

Apache::ProxyPassThru - Skeleton for vanilla proxy

=head1 SYNOPSIS

 #httpd.conf or some such
 PerlTransHandler  Apache::ProxyPassThru::translate
 PerlHandler       Apache::ProxyPassThru

=head1 DESCRIPTION

This module uses libwww-perl as it's web client, feeding the response
back into the Apache API request_rec structure. 
`PerlHandler' will only be invoked if the request is a proxy request,
otherwise, your normal server configuration will handle the request. 

=head1 SEE ALSO

mod_perl(3), Apache(3), LWP::UserAgent(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


