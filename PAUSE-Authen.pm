=pod

Date: Mon, 9 Jun 1997 19:25:38 +0200
Message-Id: <199706091725.TAA25746@anna.in-berlin.de>
From: "Andreas J. Koenig" <k@anna.in-berlin.de>
To: Doug MacEachern <dougm@osf.org>
CC: MODPERL@LISTPROC.ITRIBE.NET
In-reply-to: <199706082250.SAA01428@postman.opengroup.org> (message from Doug
	MacEachern on Sun, 8 Jun 1997 18:50:16 -0400)
Subject: Re: How do I get Authen.pm to work?
Reply-to: koenig@franz.ww.tu-berlin.de
X-UIDL: 0e08d50b2bd518afc44a1eb8a02c9563

[...]

Maybe you'd like to use the PAUSE::Authen module as an example. It's
actually used on the Perl Authors Upload Server in "production" code.

PAUSE::Authen implements a case-insensitive
authorization/authentification combination. If I cannot identify a
user from his userid, I give him a second chance on the uppercased
username and retry. On success I change his userid to the uppercase
one.

Maybe it helps somebody to get started. Here it goes....

---------8<---------------
=cut

package PAUSE::Authen;
use Apache ();
use strict;
use Apache::Constants qw(OK AUTH_REQUIRED DECLINED);
use HTTPD::UserAdmin;

sub handler {
    my($r) = @_;
    return OK unless $r->is_initial_req; #only the first internal request
    my($res, $sent_pw) = $r->get_basic_auth_pw;
    # warn "res[$res]sent_pw[$sent_pw]";
    return $res if $res; #decline if not Basic

    my $user = $r->connection->user;
    # warn "user[$user]";

    my $pw_file = $r->dir_config("AuthUserFile") || "/usr/local/etc/httpd/etc/passwd";
    # warn "AuthUserFile[$pw_file]";

    my $u = HTTPD::UserAdmin->new(
				  DB      => $pw_file,
				  DBType  => "Text",
				  Server  => "apache",
				  Locking => 0,
				  Flags   => "r",
				 );

    # The famous PAUSE case-insensitive authentification:
    unless ($user eq uc $user or $u->exists($user)){
	$user = uc $user;
	$r->connection->user($user);
    }
    my $crypt_pw  = $u->password($user);
    my($expect) = crypt($sent_pw,$crypt_pw);
    unless ($u->exists($user) and $expect eq $crypt_pw) {
	$r->log_reason("Either user[$user] or passwd wrong. crypt from passwd[$crypt_pw] crypt from sent[$expect]", $r->uri);
	$r->note_basic_auth_failure;
	return AUTH_REQUIRED;
    }
    return OK;
}

1;

=head1 MEMO for PAUSE::Authen

In .htaccess we have:

PerlSetVar AuthUserFile /usr/local/etc/httpd/etc/passwd
AuthName PAUSE
AuthType Basic
<Limit GET POST>
require valid-user
</Limit>

In access.conf we find:

<Location /perl/user>
PerlAuthenHandler PAUSE::Authen
</Location>

=cut
