package Apache::Authen;
use strict;
use HTTPD::UserAdmin ();
use Apache ();
use Apache::Constants qw(OK AUTH_REQUIRED);

sub check {
    my($self, $r, $attr) = @_;
    my($res, $sent_pwd, $passwd);

    ($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic
    
    my $user = $r->connection->user;

    my $u = HTTPD::UserAdmin->new(%$attr);
    unless($passwd = $u->password($user)) {
	$r->log_reason("User '$user' not found", $r->uri);
	$r->note_basic_auth_failure;
	return AUTH_REQUIRED;
    }

    unless(crypt($sent_pwd, $passwd) eq $passwd) {
	$r->log_reason("user $user: password mismatch", $r->uri);
	$r->note_basic_auth_failure;
	return AUTH_REQUIRED;
    }
    return OK;
}

1;

__END__

=head1 NAME

Apache::Authen - Building blocks for mod_perl PerlAuthenHandler's

=head1 SYNOPSIS

use Apache::Authen ()

=head1 DESCRIPTION

Building blocks for mod_perl PerlAuthenHandler's

=head1 METHODS

=over 4

=item Apache::Authen->check($r, \%attr)

This method looks up the username and password via HTTPD::UserAdmin testing
for a valid password if user is found.
Returns C<OK> upon success, otherwise returns C<AUTH_REQUIRED>.
C<$r> is a request_rec object blessed into the L<Apache> class.
C<\%attr> is a hash reference passed to HTTPD::UserAdmin->new.

=back

=head1 SEE ALSO

Apache(3), HTTPD::UserAdmin(3), Apache::AuthenDBI(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>
