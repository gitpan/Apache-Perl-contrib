package Apache::SSI;
use Apache ();
use Apache::Options qw(&OPT_EXECCGI); #for exec
use HTML::TreeBuilder ();
use HTTP::Date;
use File::Basename;

use vars qw($VERSION @ISA);

@ISA = qw(HTML::TreeBuilder);

#$Id: SSI.pm,v 1.14 1997/03/10 00:25:45 dougm Exp $
$VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

#wherever you choose:
#AddHandler perl-script .phtml

#add this to srm.conf:
#PerlModule Apache::SSI

#in access.conf or .htaccess say:
#PerlResponse Apache::SSI::handler

sub handler {
    my($r) = @_;
    %ENV = $r->cgi_env; #for exec
    $r->content_type("text/html"); 
    $r->send_http_header;
    my $p = Apache::SSI->new($r);
    $p->parse_file($r->filename);
    $r->print($p->as_HTML);
}

sub magic_type {
    my($self, $file) = @_;
    $file =~ /\.phtml$/; #temp hack for 'include' directive
}

sub find_file {
    my($self, $args) = @_;
    my($file,$virtual) = @{$args}{qw(file virtual)};
    my $ret;
    return if $file =~ /^\.\./;
    my $r = $self->{_r};
    my $base = dirname $r->filename;
    if($file !~ m,^/,,) {
	$ret = join "/", $base, $file;
    }
    return $ret if -e $ret;
    $r->log_error("Apache::SSI couldn't find file $to_parse $!");
    undef;
}

sub new {
    my($class, $r) = @_;
    my $self = $class->SUPER::new;
    $self->{_r} = $r;
    $self;
}

sub perlsub {
    my($self, $args) = @_;
    my $sub = $args->{sub};
    return defined &{$sub} ? &{$sub} : &{"main\:\:$sub"};
}

sub comment {
    my($self, $comment) = @_;
    return unless $comment =~ s/^#//;
    $comment =~ s/\s*$//;
    my($action, $args) = split /\s+/, $comment, 2;
    $self->pos->push_content($self->$action({ split(/\s+|=/, $args) }));
}

sub echo {
    my($self, $args) = @_;
    my $r = $self->{_r};
    &{"$args->{var}"}($r);
}

sub DATE_GMT { time2str; }
sub DATE_LOCAL { scalar localtime; }
sub DOCUMENT_NAME { basename $_[0]->filename; }
sub DOCUMENT_URI { $_[0]->uri; }
sub LAST_MODIFIED { lastmod($_[0]->filename); }

sub fsize { 
    my($self,$args) = @_;
    (stat($self->find_file($args)))[7]; 
}

sub lastmod {
    my($file) = @_;
    time2str((stat($file))[9]);
}

sub flastmod {
    my($self, $args) = @_;
    lastmod($args->{file} || $self->{_r}->filename);
}

sub exec {
    my($self, $args) = @_;
    #XXX did we check enough?
    my $r = $self->{_r};
    my $filename = $r->filename;
    unless($r->allow_options & OPT_EXECCGI) {
	$r->log_error("httpd: exec used but not allowed in $filename");
	return "";
    }
    `$args->{cmd}`;
}

sub include {
    my($self, $args) = @_;
    my $r = $self->{_r};
    my $p = Apache::SSI->new($r);
    my $to_parse = $self->find_file($args);

    if($p->magic_type($to_parse)) {
	$p->parse_file($to_parse);
	return $p->as_HTML;
    }
    else {
	local *FH;
	open FH, $to_parse; # or $r->log_error
	return join '', <FH>; #eek
	#close FH;
    }
    undef;
}

sub config {
    "*** 'config' directive not implemented by Apache::SSI";
}

#test for perlsub directive
sub main::remote_host { $ENV{REMOTE_HOST}; }
sub main::env {
    join('', map {
	"$_ = $ENV{$_}\n";
    } keys %ENV);
}

1;

__END__

=head1 NAME

Apache::SSI - Implement Server Side Includes in Perl

=head1 SYNOPSIS

wherever you choose:

<Files *.phtml>
SetHandler perl-script
PerlHandler Apache::SSI
</Files>

You may wish to subclass Apache::SSI for your own extentions

    package MySSI;
    use Apache::SSI ();
    @ISA = qw(Apache::SSI);

    #embedded syntax:
    #<!--#something cmd=doit -->
    sub something {
       my($self, $attr) = @_;
       my $cmd = $attr->{cmd};
       ...
       return $a_string;	   
    } 

=head1 DESCRIPTION

Apache::SSI implements the functionality of mod_include for handling
server-parsed html documents.
Each "command" or element is handled by an Apache::SSI method of the
same name.  attribute=value pairs are parsed and passed to the method
in an anonymous hash.

This module supports the same directives as mod_include, see it's 
documentation for commands and syntax.

In addition, Apache::SSI supports the following directives:

=item perlsub

This directive calls a perl subroutine:

 Hello user from <!--#perlsub sub=remote_host -->

=head1 CAVEATS

This module is not complete, it does not provide the full functionality 
of mod_include.  

There is no support for xssi directives.

=head1 SEE ALSO

For much more power, see the L<HTML::Embperl> and L<Apache::ePerl> modules. 

mod_include, mod_perl(3), HTML::TreeBuilder(3), Apache(3),
HTML::Embperl(3), Apache::ePerl(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>
