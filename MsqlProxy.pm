package Apache::MsqlProxy;

use Apache ();
use Msql ();
use URI::URL ();
use Apache::Constants;

sub Apache::MsqlProxy::translate {
    my($r) = @_;

    return DECLINED unless $r->proxyreq;
    $r->handler("perl-script");
#    my $cld = get Apache::ModuleConfig $r->server->per_dir_config;
#    $cld->PerlHandler("Apache::MsqlProxy::handler");
    return OK;
}

sub Apache::MsqlProxy::handler {
    my($r) = @_;
    my $url = new URI::URL $r->uri;
    my $host = $url->host || "";
    my $port = $url->port; 

    $ENV{'MSQL_TCP_PORT'} = $port if $port != 80; #hmm
    my($db, $table, $info) = $url->path =~ /(\w+|\*)/g;
    $r->path_info($info);
    my(%select);
    %select = $url->query_form if $url->query =~ /=/;
    my $dbh = Msql->connect($host);
    $dbh->selectdb($db); 
    my $query = gen_select($r, $table, [keys %select], \%select);
    my $sth;
    unless($sth = $dbh->query($query)) {
	$r->log_error($Msql::errstr);
	return SERVER_ERROR;
    }
    $r->content_type("text/html");
    $r->send_http_header();

    $r->print("<table border=1><tr><td>", join("</td><td>", @{$sth->name}), "</td></tr>");
    while (@row = $sth->fetchrow()){
	$r->print("<tr><td>" , join("</td><td>", @row), "</td></tr>");
    }
    $r->print("</table>");
    return OK;
}

#ick
sub gen_select {
    my($r, $table, $names, $values, $op) = @_;
    $op ||= '=';
    my $what = $names->[0] ? join ", ", @{$names} : "*";
    $what = "*" if $r->path_info;
    my $where;
    if(scalar keys %$values) {
	my(@cond);
	foreach(keys %{$values}) {
	    next unless  $values->{$_};
	    push @cond,  " $_ $op '$values->{$_}' ";
	}
	my $cond = (@cond == 1) ? "$cond[0]" : join(" and ", @cond);
	$where = $cond ? " WHERE $cond " : "*";
    }
    "SELECT $what from $table $where";
}

1;

__END__

=head1 NAME

Apache::MsqlProxy - Translate URI's into mSQL database queries

=head1 SYNOPSIS

 #httpd.conf or srm.conf
 PerlTransHandler Apache::MsqlProxy::translate
 PerlHandler      Apache::MsqlProxy::handler
 PerlModule       Apache::MsqlProxy

Configure your browser's HTTP proxy to point at the host running Apache configured 
with this module:

  http://hostname.domain/

When connecting to the server via normal HTTP (not proxy), URLs are not translated.

URL's are translated as follows:

 http://hostname/database_name/table_name

Connect to B<hostname> via TCP, select database B<database_name>, query table <table_name> with:

 SELECT * from table_name

 http://hostname/database_name/table_name?login_name=dougm

Same as above with query:

 SELECT login_name from table where login_name=dougm

 http://hostname/database_name/table_name/*?login_name=dougm

Same as above with query:

 SELECT * from table where login_name=dougm

Of course,

 http:///database_name/table_name

A null hostname connects via UNIX socket

 http://hostname:9876/database_name/table_name

Connect via TCP to hostname and port 9876


=head1 DESCRIPTION

This module is meant as an example to show how one can use Apache + mod_perl
to handle HTTP proxy requests, or simply translating a URL.

It may not be very useful other than as an example, but feel free to change that.

=head1 SEE ALSO

Apache(3), Msql(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

