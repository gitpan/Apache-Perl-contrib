=pod
Date:         Sun, 7 Sep 1997 09:54:51 -0700
Reply-To: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
Sender: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
From: Randal Schwartz <merlyn@STONEHENGE.COM>
Subject:      Cool.  replaced a mod_rewrite with a PerlTransHandler!
To: MODPERL@LISTPROC.ITRIBE.NET
X-UIDL: 2ebcec247710a529ef4e463621590e4e

OK.  I think I'm starting to get the hang of this.  I am testing my
local mod_perl-powered server nearby www.stonehenge.com, and I wanted
some *content*, but still wanted to try some /perl things (using
Apache::Registry).

So I got this idea to have a local htdoc area merely shadow the
original www.stonehenge.com pool, including CGI areas.  In other
words, if it could find it locally, use it, otherwise deliver the docs
as if I had accessed the original server.  Since I have access to the
same filesystem, it seemed easy enough.

At first, I had installed the mod_rewrite lines:

    ## turn on the engine
    RewriteEngine on
    RewriteLogLevel 9
    RewriteLog logs/rewrite_log

    # local cgi overrides other
    RewriteCond %{REQUEST_URI} ^/cgi/
    RewriteCond /home/merlyn/etc/httpd/htdocs%{REQUEST_FILENAME} -f
    RewriteRule ^ - [PT]

    # other cgi
    RewriteRule ^/cgi/(.*)$ /WWW/stonehenge/cgi-bin/$1 [L]
    RewriteRule ^/cgi-bin/(.*)$ /WWW/stonehenge/cgi-bin/$1 [L]

    # local htdocs overrides other
    RewriteCond %{REQUEST_URI} ^/(manual|perl)/
    RewriteRule ^ - [PT]

    # other htdocs
    RewriteRule ^/(.*)$ /WWW/stonehenge/htdocs/$1 [L]

which seemed to be working fine.  I didn't like that I had to know the
document root here, though.  It seemed, uh, dirty. :-)

So then I gets this strange idea in my head to write my first
PerlTransHandler which should take the place of this.  And after a
dozen or so iterations (mostly realizing that My::Trans wasn't being
reload often enough, requiring a lot more kill -1's than I though), I
came up with this:

    ## install as
    ## PerlTransHander My::Trans
=cut

    package My::Trans;

    use strict;

    my $other = "/WWW/stonehenge";
    my $other_cgi = "$other/cgi-bin";
    my $other_root = "$other/htdocs";

    sub handler {
      my $r = shift;

      if ($r->is_initial_req) {
        $r->warn("request: ".$r->the_request);
      }

      my $document_root = $r->document_root;
      my $uri = $r->uri;

      local $_ = $uri;

      ## local /cgi/
      if (m{^/cgi/} and -x "$document_root$_") {
        $r->warn("$uri => using local CGI at $document_root$_");
        $r->filename("$document_root$_");
        return 0;
      }
      ## old /cgi/ or /cgi-bin/
      if (s{^/(cgi|cgi-bin)/}{$other_cgi/}) {
        $r->warn("$uri => using remote CGI at $_");
        $r->filename($_);
        return 0;
      }
      ## local /manual/ or /perl/
      if (m{^/(manual|perl)(/|$)}) {
        $r->warn("$uri => using local file at $document_root$_");
        $r->filename("$document_root$_");
        return 0;
      }
      ## any old prior
      if (s{^/}{$other_root/}) {
        $r->warn("$uri => using remote file at $_");
        $r->filename($_);
        return 0;
      }
      $r->warn("$uri => huh?");
      return -1;
    }

    1;

__END__

So I offer this as an example of something tiny but slick that can
be done with PerlTransHandler's.

--
Name: Randal L. Schwartz / Stonehenge Consulting Services (503)777-0095
Keywords: Perl training, UNIX[tm] consulting, video production, skiing, flying
Email: <merlyn@stonehenge.com> Snail: (Call) PGP-Key: (finger merlyn@ora.com)
Web: <A HREF="http://www.stonehenge.com/merlyn/">My Home Page!</A>
Quote: "I'm telling you, if I could have five lines in my .sig, I would!" -- me

