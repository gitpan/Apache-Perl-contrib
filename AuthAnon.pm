package Apache::AuthAnon;

use strict;
use Apache::Constants ':common';

sub handler {
    my $r = shift;

    my($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my $user = lc $r->connection->user;

    unless($user eq "anonymous" and $sent_pwd) {
	$r->note_basic_auth_failure;
	return AUTH_REQUIRED;
    }

    $r->warn("Anonymous: Passwd <$sent_pwd> Accepted");

    return OK;
}

1;
__END__

=head1 NAME

Apache::AuthAnon - Anonymous logon module

=head1 SYNOPSIS

 AuthType Basic
 AuthName Anonymous
 PerlAuthenHandler Apache::AuthAnon
 require valid-user

=head1 DESCRIPTION

This module was just an example for the Apache/Perl talk at the first
ORA Perl conference. 
Still, it works, but mod_auth_anon provides more functionality.

=head1 SEE ALSO

mod_auth_anon, mod_perl(3), Apache(3)

=head1 AUTHOR

Doug MacEachern
