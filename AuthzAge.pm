package Apache::AuthzAge;
use strict;
use Apache::Constants ':common';
use NDBM_File;
use Fcntl '&O_RDONLY';

my $Flags = O_RDONLY;
 
sub handler {
    my($r) = @_;
    return OK unless $r->is_initial_req; #only the first internal request
    my $reqs_arr = $r->requires;
    return OK unless $reqs_arr;

    my $dbm_file = $r->dir_config("UserAgeFile") or
	return DECLINED;
    my %Age;
    unless(tie(%Age => 'NDBM_File', $dbm_file, $Flags, undef)) {
	$r->log_reason("Can't open $dbm_file $!", $r->uri);
	return SERVER_ERROR;
    }

    my($reqs, $restricted, $require, $min_age);
    my $user = $r->connection->user;

    foreach $reqs (@$reqs_arr) {
	($require, $min_age) = split /\s+/, $reqs->{requirement}, 2;
	next unless $require eq "age";
	$restricted++; 
	return OK if $Age{$user} >= $min_age; 
    }

    return OK unless $restricted;
    $r->log_reason("User $user younger than $min_age", $r->uri);
    $r->note_basic_auth_failure;
    return FORBIDDEN;
}

1;

__END__

=head1 NAME

Apache::AuthzAge - Authorize based on age

=head1 SYNOPSIS

 #access control directives

 #use standard authentication modules
 AuthName SomeRealm
 Auth[DBM]UserFile /path/to/password/file
 
 PerlAuthzHandler Apache::AuthzAge
 PerlSetVar       UserAgeFile  /path/to/dbm_file

 #user must be at least 21
 <Limit GET>
 require age 21
 </Limit>

=head1 DESCRIPTION

Decide if an authenticated user is authorized to complete a request
based on age.  

B<UserAgeFile> is a dbm file consisting of I<username> = I<age> value 
pairs.

=head1 SEE ALSO

Apache(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>




