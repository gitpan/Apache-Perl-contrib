=pod

Date:         Wed, 22 Oct 1997 10:23:26 -0700
Reply-To: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
Sender: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
From: Randal Schwartz <merlyn@STONEHENGE.COM>
Subject:      little test harness I wrote
To: MODPERL@LISTPROC.ITRIBE.NET
X-UIDL: b26a138c4eae804406c0b5333362ce1b

Might be useful to tell if you are mod_perl'ing or just CGI-ing:

=cut

    #!/home/merlyn/bin/perl -Tw
    use strict;
    $|++;
    use CGI qw/:all/;
    print header('text/plain');
    use vars qw($counttime);
    BEGIN { $counttime = 0; }
    {
      $ENV{PATH} =~ /^/;
      local $ENV{PATH} = join ":", "/bin", "/usr/bin", split /:/, $&;
      ## $< = $>;
      ## $( = $);
      print scalar localtime, "\n";
      printf
        "process %d active for %d seconds (user = %.2f, sys = %.2f)\n",
        $$, time - $^T, (times)[0,1];
      print "this script re-used ", $counttime++, " times\n";
      for (qw(id hostname /bin/pwd)) {
        print `$_`;
      }
      for (sort keys %ENV) {
        print "$_=$ENV{$_}\n";
      }
      for (param()) {
        print "param $_ = ", map ("<$_>", param($_)), "\n";
      }
      print "\@INC is ", join (":", @INC), "\n";
    }

=pod

Notice the "reuse" count.  If you are running in mod_perl, that'll
tell you how many times each script has been used after the first
compile.  For CGI, that'll always be "1", and the process will be
relatively short-lived.

It also dumps out all those other cool things.  Very handy for peeking
under the hood.

Doug, if you wanna stick this in contrib, feel free.

--
Name: Randal L. Schwartz / Stonehenge Consulting Services (503)777-0095
Keywords: Perl training, UNIX[tm] consulting, video production, skiing, flying
Email: <merlyn@stonehenge.com> Snail: (Call) PGP-Key: (finger merlyn@ora.com)
Web: <A HREF="http://www.stonehenge.com/merlyn/">My Home Page!</A>
Quote: "I'm telling you, if I could have five lines in my .sig, I would!" -- me

=cut
