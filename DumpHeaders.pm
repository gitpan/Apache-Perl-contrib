package Apache::DumpHeaders;
use Apache ();

sub handler {
    my($r) = @_;
    my($k,$v);
    my $file = $r->dir_config("DumpHeadersFile") or return -1;
    local *OUT;
    open OUT, ">$file" or die "Failed to open $file";
    print OUT $r->as_string;
    close OUT;
    return -1;
}

1;

__END__

=head1 NAME

Apache::DumpHeaders - Watch HTTP transaction via headers

=head1 SYNOPSIS

 #httpd.conf or some such
 PerlLogHandler Apache::DumpHeaders
 PerlSetVar     DumpHeadersFile -

=head1 DESCRIPTION

This module is used to watch an HTTP transaction, looking at client and
servers headers.  DumpHeadersFile may be a filename or `-' for STDOUT.
With Apache::ProxyPassThur configured, you are able to watch your browser
talk to any server besides the one with this module living inside.

=head1 SEE ALSO

mod_perl(3), Apache(3), Apache::ProxyPassThru(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


