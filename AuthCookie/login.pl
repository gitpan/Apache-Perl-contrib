#!/user/local/bin/perl
use strict;
my $r = Apache->request;

$r->no_cache(1);
$r->content_type("text/html");
$r->send_http_header;

my $uri = $r->uri;
my $a_type = $r->auth_type;
my $a_name = $r->auth_name;

my $form = <<HERE;
<HTML>
<HEAD>
<TITLE>Enter Username and Password</TITLE>
</HEAD>
<BODY>
<P>Please enter your Username and Password to authenticate.</P>
<FORM METHOD="POST" ACTION="$uri">
<INPUT TYPE="hidden" NAME="AuthType" VALUE="$a_type">
<INPUT TYPE="hidden" NAME="AuthName" VALUE="$a_name">
<TABLE>
<TR>
<TD ALIGN=RIGHT><B>PID:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_0" SIZE=9 MAXLENGTH=9></TD>
</TR>
<TR>
<TD ALIGN=RIGHT><B>PAC:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_1" SIZE=8 MAXLENGTH=8></TD>
</TR>
<TR>
<TD COLSPAN=2 ALIGN=CENTER><INPUT TYPE="submit" VALUE="Continue"></TD>
</TR>
</TABLE>
</FORM>
</BODY>
</HTML>
HERE

$r->print ($form);
