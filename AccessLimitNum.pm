package Apache::AccessLimitNum;
use strict;
use Apache::Constants ':common';
use NDBM_File;
use Fcntl qw(&O_RDWR &O_CREAT);

my $Flags = O_RDWR|O_CREAT;
 
sub handler {
    my($r) = @_;

    return OK unless $r->is_initial_req; #only first internal request

    my $limit_num = $r->dir_config("AccessLimitNum") or
	return DECLINED;
    my $dbm_file = $r->dir_config("AccessLimitNumFile") or
	return DECLINED;

    my %AccessNum;
    unless(tie(%AccessNum => 'NDBM_File', $dbm_file, $Flags, undef)) {
	$r->log_reason("Can't open $dbm_file $!", $r->uri);
	return SERVER_ERROR;
    }

    my $user = $r->connection->user;
    return DECLINED unless $user;

    my $status = OK; 
    if(++$AccessNum{$user} >= $limit_num) {
	$r->log_reason("User $user access limit exceeded $limit_num", $r->uri);
        $r->note_basic_auth_failure;
	$status = FORBIDDEN;
    }
    untie %AccessNum;
    return $status;
}

1;

__END__

=head1 NAME

Apache::AccessLimitNum - Limit user access by number of requests

=head1 SYNOPSIS

 #server config or .htaccess

 #use any authentication module
 AuthName SomeRealm
 Auth[DBM]UserFile /path/to/password/file
 
 PerlAccessHandler Apache::AccessLimitNum
 PerlSetVar        AccessLimitNum  100
 PerlSetVar        AccessLimitFile /path/to/limit/file

 <Limit GET>
 require valid-user #or some such
 </Limit>

=head1 DESCRIPTION

Decide if an authenticated user has exceeded an access limit for the 
requested realm, if so, forbid access.

B<AccessLimitFile> is a dbm file consisting of I<username> = I<number> value 
pairs.  This file must be writeable by httpd server process.

=head1 SEE ALSO

Apache(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>




