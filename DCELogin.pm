package Apache::DCELogin;
use Apache::Constants ':common';
use DCE::Login ();
use DCE::Status;
use strict;

my $l; #need to maintain login context for the request lifetime

sub failed {
    my($r,$status) = @_;
    $r->log_reason(error_inq_text($status), $r->uri) if $status;
    purge();
    return AUTH_REQUIRED;
}

sub handler {
    my $r = shift;
    return DECLINED unless $r->is_main;
    
    my($res, $pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my($status, $ok, $valid, $reset, $auth_src, $uid);
    
    unless($uid = $r->connection->user and $pwd) {
	$r->note_basic_auth_failure;
	return failed($r,$status);
    }

    ($l, $status) = DCE::Login->setup_identity($uid); 
    return failed($r,$status) if $status != OK;

    ($valid, $reset, $auth_src, $status) = 
	$l->validate_identity($pwd);
    return failed($r,$status) if $status != OK;

    if($valid) {
	($ok, $status) = $l->certify_identity;

	return failed($r,$status)	if $status != OK;

	$r->log_error("${uid}'s password must be changed!") if $reset;

	if($auth_src == $l->auth_src_local) {
	    $r->log_error("${uid}'s credentials obtained from local registry.");
	}
	elsif($auth_src == $l->auth_src_overridden) {
	    $r->log_error("$uid validated from local override entry, no network credentials obtained.");
	}
	else {
	    $status = $l->set_context;
	    return failed($r,$status) if $status != OK;
	}
    }
    else {
	return failed($r,$status);
    }
    return OK;
}

sub purge {
    $l->purge_context if $l;
    undef $l;
    return DECLINED; #well, we didn't really log anything
}

1;

__END__

=head1 NAME

Apache::DCELogin - Obtain a DCE Login context

=head1 SYNOPSIS

 #access.conf or some such
 AuthType Basic
 AuthName "DCE-Perl Login"
 PerlAuthenHandler Apache::DCELogin
 PerlLogHandler    Apache::DCELogin::purge

=head1 DESCRIPTION

Apache::DCELogin obtains a DCE login context with the username and password
obtained via the Basic authentication challenge.

=head1 SEE ALSO

mod_perl(3), Apache(3), DCE::Login(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


