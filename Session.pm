package Apache::Session;

use strict;
use URI::URL ();
use IO::File ();
use File::CounterFile ();
use CGI::Switch ();
use Apache::Constants ':common';
use File::Path 'mkpath';
use File::Basename;
use File::Copy 'cp';

sub handler {
    my $r = shift;
    return DECLINED unless -x $r->server_root_relative("httpd");
    
    Apache->request($r); 
    my $q = new CGI::Switch;
    my(%id) = $q->cookie('session');
    my $path = $r->uri;
    my $port = $id{port} || allocate_port($r);

    warn "id->port=$id{port} ($port) server->port=", $r->server->port;
    return DECLINED if exists $id{port} and ($id{port} eq $r->server->port);

    my $c = File::CounterFile->new("HTTPD_SESSION","00000000");
    my $sdir = join "/",  
    ($r->dir_config("SessionBaseDir") || "/tmp/httpd_sessions"),
    $c->value;

    unless ($id{seskey} and -d $sdir) { 
	$id{port} = $port;
	$id{seskey} = $c->inc;

	warn "creating new session seskey=$id{seskey}\n";
	my $cookie = $q->cookie(-name=>'session',
		     -value=>\%id,
		     -expires=>'+1h');
	for(qw(header_out err_header_out)) {
	    $r->$_("Set-Cookie" => $cookie);
	}

	start_server($r, $sdir, $port);
    }
    return redirect($r, $r->uri, $port);
}

sub allocate_port {
    my($r) = @_;
    my $c = File::CounterFile->new("HTTPD_SESSION_PORT","9000");
    $c->inc;
    $c->inc if $c->value eq $r->server->port;
    $c->inc while(getservbyport($c->value, "tcp"));
    $c->value;
}

sub start_server {
    my($r, $root, $port) = @_;
    my $httpd_conf = $r->server_root_relative("conf/httpd.conf");
    my $base_conf = dirname $httpd_conf;
    $port ||= $$;

    mkpath $root, 0, 0755;
    for ("$root/conf", "$root/logs") {
	mkdir $_, 0755;
    }

    my $in = IO::File->new($httpd_conf);
    $httpd_conf = "$root/conf/httpd.conf";

    unless (-e $httpd_conf) {
	my $out = IO::File->new(">$httpd_conf");
	while(<$in>) {
	    if (/^Port/) {
		print $out "Port $port\n";
	    }
	    elsif (/^ServerRoot/) {
		print $out "ServerRoot $root\n";
	    }
	    else {
		print $out $_;
	    }
	}
	for(<$base_conf/*.*>) {
	    cp $_, "$root/conf";
	}
    }

    my $old_path = $ENV{PATH}; 
    $ENV{PATH} = "/bin";
    my $httpd = $r->server_root_relative("httpd");
    system "$httpd -X -d $root &";
    $ENV{PATH} = $old_path;
    warn "started $httpd ($root)\n";
}

sub redirect {
    my($r, $path, $port) = @_;
    my $uri = new URI::URL $r->uri;
    $uri->scheme("http");
    $uri->host($r->server->server_hostname);
    $uri->port($port);
    $uri->epath($path);
    $r->content_type("text/html");
    $r->header_out(Location => $uri->abs->as_string);
    $r->status(302);
    return 302;
}

1;

__END__

=head1 NAME

Apache::Session - Maintain client <-> httpd instance session

=head1 SYNOPSIS

 #httpd.conf or some such
 PerlFixupHandler Apache::Session

 #where to store session config files (default is /tmp/httpd_sessions)
 PerlSetVar       SessionBaseDir

=head1 DESCRIPTION

This module starts a session based httpd for a specific client.
By using HTTP cookies, the server redirects the client to it's session
on a dynamically allocated port.  

=head1 TODO

=over 4

=item re-configuration issues, what else needs to be changed?

=item ensure server is started properly

=item cleanup when server shuts down

=item expire session

=item reset session and port counters

=item validate peer identity

=item httpd might not be in ServerRoot and it might not be called `httpd'

=back

=head1 SEE ALSO

mod_perl(3), Apache(3), File::CounterFile(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


