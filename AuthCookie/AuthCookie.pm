package Apache::AuthCookie;
use strict;
use Apache::Constants qw(:common M_GET M_POST);
require Devel::Symdump;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter ();

$VERSION = substr(q$Revision: 1.2 $, 10);
@ISA = qw(Exporter);
@EXPORT_OK = qw(&authen &authz);
 
sub authen ($$) {
    my $that = shift;
    my $r = shift;
    my($ses_key_str, $cookie_path, $authen_script);
    my($auth_user, $auth_name, $auth_type);
    my @ses_key;

    $r->log_error("that " . $that);
    return OK unless $r->is_initial_req; #only the first internal request

    $auth_type = $that;
    $auth_type =~ s/::.*//;
    $r->log_error("auth_type " . $auth_type);

    if ($r->auth_type ne $auth_type)
    {
	# This location requires authentication because we are being called,
	# but we don't handle this AuthType.
	#$r->log_error($auth_type . "::Auth:authen auth type is " . $r->auth_type);
	return DECLINED;
    }

    # Ok, the AuthType is $auth_type which we handle, what's the authentication
    # realm's name?
    $auth_name = $r->auth_name;
    $r->log_error("auth_name " . $auth_name);
    if (!($auth_name))
    {
	$r->log_reason($auth_type . "::Auth:authen need AuthName ", $r->uri);
	return SERVER_ERROR;
    }

    # There should also be a PerlSetVar directive that give us the path
    # to set in Set-Cookie header for this realm.
    $cookie_path = $r->dir_config($auth_name . "Path");
    if (!($cookie_path)) {
	$r->log_reason($auth_type . "::Auth:authen path not set for auth realm " .
	    $auth_name, $r->uri);
	return SERVER_ERROR;
    }


    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.
    local($_)  = $r->header_in("Cookie") || "";
    $ses_key_str = "";
    if (/${auth_type}_${auth_name}=/) {
	s/.*${auth_type}_${auth_name}=//;
	s/;.*//;
	$ses_key_str = $_;
    }

    $r->log_error("ses_key_str " . $ses_key_str);
    $r->log_error("cookie_path " . $cookie_path);
    $r->log_error("filename " . $r->filename);
    $r->log_error("uri " . $r->uri);

    if ($ses_key_str)
    {
	# Ok, there is a session key. Split it into the ses_key array
	@ses_key = split(/:/, $ses_key_str);
    }
    elsif ($r->method_number == M_POST)
    {
	# No session key set, but the method is post. We should be
	# coming back with the users credentials.

	# If not, we are eating up the posted content so the
	# user will be SOL
	my %args = $r->content;
	if ($args{'AuthName'} ne $auth_name ||
	    $args{'AuthType'} ne $r->auth_type)
	{
	    $r->log_reason($auth_type . "::Auth:authen credentials are not for" .
		 "this realm or this is not an authentication responce ",
		 $r->uri);
	    return SERVER_ERROR;
	}

	# Get the credentials from the data posted by the client
	my @credentials;
	while ($args{"credential_" . ($#credentials + 1)})
	{
	    $r->log_error("credential_" . ($#credentials + 1) . " " . $args{"credential_" . ($#credentials + 1)});
	    push(@credentials, $args{"credential_" . ($#credentials + 1)});
	}

	# Exchange the credentials for a session key. If they credentials
	# fail this should return nothing, which will fall trough to call
	# the get credentials script again
	@ses_key = $that->authen_cred($r, @credentials);
	$r->log_error("ses_key " . join(":", @ses_key));
	$r->method("GET");
	$r->method_number(M_GET);
    }
    elsif ($r->method_number != M_GET)
    {
	# They aren't authenticated, but they are trying a POST or
	# something, this is not allowed.
	$r->log_reason($auth_type . "::Auth:authen auth header is not set and method is not GET ", $r->uri);
	return SERVER_ERROR;
    }

    $r->log_error("#ses_key " . $#ses_key);
    if ($#ses_key >= 0) {
	# We have a session key. So, lets see if it's valid. If it is
	# we return with an OK value. If not then we fall through to
	# call the get credentials script.
	if ($auth_user = $that->authen_ses_key($r, @ses_key)) {
	    if (!($ses_key_str)) {
		# They session key is valid, but it's not yet set on
		# the client. So, send the Set-Cookie header.
		$r->header_out("Set-Cookie" => $auth_type . "_" . $auth_name .
		    "=" .  join(":", @ses_key) . "; path=" .  $cookie_path);
		$r->log_error("set_cookie " . $r->header_out("Set-Cookie"));
	    }
	    # Tell the rest of Apache what the authentication method and
	    # user is.
	    $r->connection->auth_type($auth_type);
	    $r->connection->user($auth_user);
	    $r->log_error("user authenticated as " . $auth_user);
	    return OK;
	}
    }

    # There was a session key set, but it's invalid for some reason. So,
    # remove it from the client now so when the credential data is posted
    # we act just like it's a new session starting.
    if ($ses_key_str) {
	$r->header_out("Set-Cookie" => $auth_type . "_" . $auth_name .  "=; path=" .
	    $cookie_path . "; expires=Mon, 21-May-1971 00:00:00 GMT");
	#$r->query_string("invalid");
	$r->log_error("set_cookie " . $r->header_out("Set-Cookie"));
    }

    # They aren't authenticated, and they tried to get a protected
    # document. Send them the authen form.

    # Tell authorization that we are headed for the authentication page.
    $r->notes("AUTHZ_PASS", 1);

    # There should also be a PerlSetVar directive that give us the name
    # and location of the script to execute for the authen page. If this
    # doesn't begin with a '/' it's relative to the document root.
    $authen_script = $r->dir_config($auth_name . "AuthenticationScript") || "";
    if (!($authen_script)) {
	$r->log_reason($auth_type . 
	    "::Auth:authen authentication script not set for auth realm " .
	    $auth_name, $r->uri);
	return SERVER_ERROR;
    }
    if ($authen_script !~ m|^/|) {
	my $document_root = $r->document_root;
	$document_root .= "/" unless $document_root =~ m|/$|;
	$authen_script = $document_root . $authen_script;
    }

    # I tried to use an internal redirect, but at this stage in the game
    # I guess it's to late or early for that. So, let's beat the server
    # up-side the head and make it run the script to prompt for credentials
    $r->filename($authen_script);
    $r->handler("perl-script");
    $r->push_handlers("PerlHandler", \&Apache::Registry::handler);
    $r->method("GET");
    $r->method_number(M_GET);

    $r->log_error("sending you to the authentication page ");
    $r->log_error("method " . $r->method);
    $r->log_error("filename " . $r->filename);
    return OK;
}

sub authz ($$) {
    my $that = shift;
    my $r = shift;
    my($auth_name, $auth_type);

    return OK unless $r->is_initial_req; #only the first internal request

    $auth_type = $that;
    $auth_type =~ s/::.*//;

    if ($r->auth_type ne $auth_type) {
	#$r->log_error($auth_type . "::Auth:authz auth type is " . $r->auth_type);
	return DECLINED;
    }

    # The authentication routine has redirected us to the authentication
    # page to get a PID and PAC, so always Ok this as authorized
    my $note = $r->notes("AUTHZ_PASS") || "";
    $r->log_error($auth_type . "::Auth:authz note $auth_type " . $note);
    return OK if ($note);

    my $reqs_arr = $r->requires;
    return OK unless $reqs_arr;

    my $user = $r->connection->user;
    if (!($user)) {
	# user is either undef or =0 which means the authentication failed
	$r->log_reason("No user authenticated", $r->uri);
	return FORBIDDEN;
    }

    my($reqs, $requirement, $args, $restricted);
    foreach $reqs (@$reqs_arr) {
        ($requirement, $args) = split /\s+/, $reqs->{requirement}, 2;
	$r->log_error("requirement := $requirement, $args");

	if ($requirement eq "valid-user") {
	    return OK;
	} elsif ($requirement eq "user") {
	    return OK if ($args =~ m/\b$user\b/);
	} else {
	    my $req_method;
	    if ($req_method = $that->can($requirement)) {
		my $ret_val = &$req_method($that, $r, $args);
		$r->log_error($that . 
		  " called requirement method " . $requirement . 
		  " which returned " . $ret_val);
		return OK if ($ret_val == OK);
	    } else {
		$r->log_error($that . 
		    " tried to call undefined requirement method " .
		    $requirement);
	    }
	}
        $restricted++;
    }

    return OK unless $restricted;
    return FORBIDDEN;
}

1;
