package Apache::Sybase::DBlib;


use Sybase::DBlib;
use strict;

sub message_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
        = @_;

        my($row);
    if ($severity > 0)
    {
        print STDERR ("Sybase message ", $message, ", Severity ", $severity,
               ", state ", $state);
        print STDERR ("\nServer `", $server, "'") if defined ($server);
        print STDERR ("\nProcedure `", $procedure, "'") if defined ($procedure);
        print STDERR ("\nLine ", $line) if defined ($line);
        print STDERR ("\n    ", $text, "\n\n");

        if(defined($db))
        {
            my ($lineno, $cmdbuff) = (1, undef);

            $cmdbuff = &Sybase::DBlib::dbstrcpy($db);

            foreach $row (split (/\n/, $cmdbuff))
            {
                print STDERR (sprintf ("%5d", $lineno ++), "> ", $row, "\n");
            }
        }
    }
    elsif ($message == 0)
    {
        print STDERR ($text, "\n");
    }

    0;
}

sub error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg)
        = @_;
    # Check the error code to see if we should report this.
    if ($error != SYBESMSG) {
        print STDERR ("Sybase error: ", $error_msg, "\n");
        print STDERR ("OS Error: ", $os_error_msg, "\n") if defined ($os_error_msg);
    }

    INT_CANCEL;
}

&dbmsghandle ("message_handler"); # Some user defined error handlers
&dberrhandle ("error_handler");

my(%Connected);

sub connect {
    my($self, @args) = @_;
        my($Uid, $Pwd, $Srv) = @args;
    my $idx = join ":", (@args) || (@{$self});
    return $Connected{$idx} if $Connected{$idx};
    print STDERR "connecting to $idx...\n" if $main::DEBUG;
    $Connected{$idx} = Sybase::DBlib->dblogin($Uid, $Pwd, $Srv);
}

sub DESTROY {
}

1;

__END__

=head1 NAME

Apache::Sybase::DBlib - persistent database connection via DBlib

=head1 SYNOPSIS

 use Apache::Sybase::DBlib;

 $dbh = Apache::Sybase::DBlib->connect($Uid, $Pwd, $Srv);

=head1 DESCRIPTION

This module provides a persistent database connection via Sybase DBlib.

All you really need is to replace Sybase::Ctlib with Apache::Sybase.
When connecting to a database the module looks if a database
handle from a previous connect request is already stored. If
not, a new connection is established and the handle is stored
for later re-use. The destroy method has been intentionally
left empty.

=head1 SEE ALSO

Apache(3)

=head1 AUTHORS

 mod_perl by Doug MacEachern <dougm@osf.org>
 Apache::DBI by Edmund Mergl <E.Mergl@bawue.de>

----------------------------------------------------
#       @(#)dblib.t     1.17    2/20/96

package TEST;

use CGI::Switch;
use Apache::Sybase::DBlib;

$obj = new CGI::Switch;

$ENV{'SYBASE'}="xxxxxxxx"; Sorry, let you fill in the xxxxx!!
$ENV{'DSQUERY'}="xxxxxxxx";
$Srv = $ENV{'DSQUERY'};
$Uid = "xxxx";
$Pwd = "xxxxxxxx";
$database = "xxx";

my($rows,$count, $ref);
$rows=0; $count=0; $ref="";

print $obj->header();
print $obj->start_html("Test of Apache::Sybase::DBlib");

# This test file is still under construction...
$Version = $SybperlVer;
$Version = $Sybase::DBlib::Version;
$Sybase::DBlib::Att{UseDateTime} = TRUE;

print "<H1>Test of Apache::Sybase::DBlib</H1>\n";
print "<PRE>\nSybperl Version $Version\n";

( $X = Apache::Sybase::DBlib->connect($Uid, $Pwd, $Srv) )
    and print("ok 1\n")
    or print "not ok 1
-- The supplied login id/password combination may be invalid\n";

( $X->dbuse('master') == &Apache::Sybase::DBlib::SUCCEED )
    and print("ok 2\n")
    or print "not ok 2\n";

($X->dbcmd("select count(*) from systypes") == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 3\n")
    or print "not ok 3\n";

($X->dbsqlexec == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 4\n")
    or print "not ok 4\n";

($X->dbresults == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 5\n")
    or print "not ok 5\n";

($count) = $X->dbnextrow;
($X->{DBstatus} == &Apache::Sybase::DBlib::REG_ROW)
    and print "ok 6\n"
    or print "not ok 6\n";

$X->dbnextrow;
($X->{DBstatus} == &Apache::Sybase::DBlib::NO_MORE_ROWS)
    and print "ok 7\n"
    or print "not ok 7\n";

($X->dbresults == &Apache::Sybase::DBlib::NO_MORE_RESULTS)
    and print("ok 8\n")
    or print "not ok 8\n";

($X->dbcmd("select * from systypes") == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 9\n")
    or print "not ok 9\n";

($X->dbsqlexec == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 10\n")
    or print "not ok 10\n";

($X->dbresults == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 11\n")
    or print "not ok 11\n";

$err = 0;
while(@row = $X->dbnextrow) {
        $rows++;
        ++$err if($X->{DBstatus} != &Apache::Sybase::DBlib::REG_ROW);
}
($err == 0)
    and print("ok 12\n")
    or print "not ok 12\n";

($count == $rows)
    and print "ok 13\n"
    or print "not ok 13, count=|$count|, rows=|$rows|\n";

# Now we make a syntax error, to test the callbacks:

&Sybase::DBlib::dbmsghandle (\&msg_handler); # different handler to check callbacks

($X->dbcmd("select * from systypes\nwhere") == &Apache::Sybase::DBlib::SUCCEED)
    and print("ok 14\n")
    or print "not ok 14\n";

($X->dbsqlexec == &Apache::Sybase::DBlib::FAIL)
    and print("ok 16\n")
    or print "not ok 16\n";

&Apache::Sybase::DBlib::dbmsghandle ("message_handler"); # Some user defined error handlers

$date1 = $X->newdate('Jan 1 1995');
$date2 = $X->newdate('Jan 3 1995');

($date1 < $date2)
    and print "ok 17\n"
    or print "not ok 17\n";

($days, $msecs) = $date1->diff($date2);
($days == 2 && $msecs == 0)
    and print "ok 18\n"
    or print "not ok 18\n";

$ref = $X->sql("select getdate()");
(ref (${$$ref[0]}[0]) eq 'Apache::Sybase::DBlib::DateTime')
        and print "ok 19\n"
    or print "not ok 19, ref=|",ref(${$$ref[0]}[0]),"|, value=|",${$$ref[0]}[0],"|\n";

print "</PRE></BODY></HTML>\n";

sub message_handler {
        my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
                = @_;

        if ($severity > 0) {
                print STDERR ("Sybase message ", $message, ", Severity ", $severity,
                                          ", state ", $state);
                print STDERR ("\nServer `", $server, "'") if defined ($server);
                print STDERR ("\nProcedure `", $procedure, "'") if defined ($procedure);
                print STDERR ("\nLine ", $line) if defined ($line);
                print STDERR ("\n    ", $text, "\n\n");

                # &dbstrcpy returns the command buffer.

                if(defined($db)) {
                        my ($lineno, $cmdbuff) = (1, undef);

                        $cmdbuff = &Apache::Sybase::DBlib::dbstrcpy($db);

                        foreach $row (split (/\n/, $cmdbuff)) {
                                print STDERR (sprintf ("%5d", $lineno ++), "> ", $row, "\n");
                        }
                }
        } elsif ($message == 0) {
                print STDERR ($text, "\n");
        }

    1;
}

sub error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg)
                = @_;
    # Check the error code to see if we should report this.
    if ($error != SYBESMSG) {
                print STDERR ("Sybase error: ", $error_msg, "\n");
                print STDERR ("OS Error: ", $os_error_msg, "\n") if defined ($os_error_msg);
    }

    INT_CANCEL;
}

sub msg_handler {
        my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
                = @_;

        if ($severity > 0) {
                ($message == 102)
                        and print("ok 15\n")
                                or print("not ok 15\n");
        }
        1;
}

----------------------------------
Last but not least, the screen dump from Netscape:
Test of Apache::Sybase::DBlib

Sybperl Version This is sybperl, version 2.07

Sybase::DBlib version 1.31 02/04/97

Copyright (c) 1991-1997 Michael Peppler


ok 1
ok 2
ok 3
ok 4
ok 5
ok 6
ok 7
ok 8
ok 9
ok 10
ok 11
ok 12
ok 13
ok 14
ok 15
ok 16
ok 17
ok 18
not ok 19, ref=||, value=|Mar 19 1997  8:12:42:713PM|

Now I have a BIG question about test 19.  The ref item is a date, but
ref(date) is null.  ??????

Sorry, but I will not have any time to maintain or update this
module.  ANYONE who wants to take it over and put their name on it is
OK with me.

--
Brian Millett
Technology Applications Inc.     "Heaven can not exist,
(314) 530-1981                          If the family is not eternal"
bpm@techapp.com                   F. Ballard Washburn

