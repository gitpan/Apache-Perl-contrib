package Apache::AuthenDBI;
use Apache ();
use Apache::Constants qw(OK);
use Apache::Authen ();
use strict;

my(%Config) = (
    AuthDBIDB => "",
    AuthDBIUserTable => "",
    AuthDBIDriver => "",
    AuthDBINameField => "user",
    AuthDBIPasswordField => "password",
    AuthDBIUser => "",
    AuthDBIAuth => "",	   
);

sub handler {
    my($r) = @_;
    return OK unless $r->is_initial_req; #only the first internal request
    my($key,$val);
    my $attr = {
	DBType => 'SQL',
    };
    while(($key,$val) = each %Config) {
	$val = $r->dir_config($key) || $val;
	$key =~ s/^AuthDBI//; 
	$attr->{$key} = $val;
    }
    $attr->{DB} = delete $attr->{User} if #bleh, inconsistent
	$attr->{Driver} eq "mSQL";
     
    return Apache::Authen->check($r, $attr);
}

1;

__END__

=head1 NAME

Apache::AuthenDBI - Authenticate via Perl DBI

=head1 SYNOPSIS

 #httpd.conf or srm.conf

 PerlModule Apache::AuthenDBI

 #.htaccess
 AuthName DBI
 AuthType Basic

 #authenticate via DBI
 PerlAuthenHandler Apache::AuthenDBI

 PerlSetVar AuthDBIDB     dbname
 PerlSetVar AuthDBIUser   username
 PerlSetVar AuthDBIAuth   password
 PerlSetVar AuthDBIDriver Oracle
 #DBI->connect(qw(AuthDBIDB AuthDBIUser AuthDBIAuth AuthDBIDriver))

 PerlSetVar AuthDBIUserTable www_users
 PerlSetVar AuthDBINameField user
 PerlSetVar AuthDBIPasswordField password

<Limit GET POST>
require valid-user
</Limit>

=head1 DESCRIPTION

Apache::AuthenDBI is a replacement for mod_auth_dbi, allowing the apache
server to authenticate via Perl's DBI.

=head1 HANDLERS

=over 4

=item Apache::AuthenDBI::handler

This handler authenticates against a database such as Oracle, DB2, Sybase,
and others supported by the DBI module.
For supported drivers see:
http://www.hermetica.com/technologia/DBI

This handler users L<HTTPD::UserAdmin> to lookup the username and password.
This may change.

=back

=head1 SEE ALSO

Apache(3), HTTPD::UserAdmin(3), DBI(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>
