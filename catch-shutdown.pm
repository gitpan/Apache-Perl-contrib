=pod

Message-ID:  <199704011823.NAA01415@postman.osf.org>
Date:         Tue, 1 Apr 1997 13:23:58 -0500
Reply-To: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
Sender: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
From: Doug MacEachern <dougm@OPENGROUP.ORG>
Subject:      httpd shutdown
To: MODPERL@LISTPROC.ITRIBE.NET
X-UIDL: f9bc42b56757df3165c92784ea76ca5a

Edmund asked yesterday, how to do something before the server shuts
down.  As Rob pointed out, the server just calls exit() once it hits
max_requests_per_child, no callback hooks or signals there.  The
current Apache->seqno method is a counter incremented only when a
PerlHandler is invoked.  This isn't so great.  The scoreboard keeps a
"real" access count per-child, you only have access to this if
compiled with -DSTATUS (default if mod_status is configured).  With
the patch below, this example PerlCleanupHandler will bail out before
the server does itself:

=cut

package MyCleanup;

#PerlCleanupHandler MyCleanup

sub handler {
    my $r = shift;
    my $left = ($r->max_requests_per_child - $r->seqno);
    if($left == 2) {
        warn "***** child $$ bailing out early *****\n";
        #... do other stuff here ...
        $r->exit;
    }
    else {
        warn "child $$ alive, $left requests left to handle\n";
    }
}

1;
__END__

I see now, you must *must* set MaxRequestsPerChild otherwise
max_requests_per_child is 0 and the server decides some other way when
to exit().  I'm sure we can come up with a better way, let me know if
it's good enough for now.

-Doug

--- 1.47        1997/04/01 04:15:11
+++ Apache.xs   1997/04/01 18:19:20
@@ -63,20 +63,40 @@
     CTRACE(stderr, "boot_Apache: items = %d\n", items);

 int
-max_requests_per_child(self)
-SV *self
+max_requests_per_child(...)

     CODE:
-    RETVAL = SvTRUE(self) ? max_requests_per_child : 0;
+    RETVAL = max_requests_per_child;
+    CTRACE(stderr, "Apache%smax_requests_per_child = %d\n", items ? "->" : "::", RETVAL);

     OUTPUT:
     RETVAL

+#include "scoreboard.h"
+
 int
 seqno(...)

+    PREINIT:
+#ifdef STATUS
+    short_score rec;
+    int i;
+    pid_t my_pid = getpid();
+#endif
+
     CODE:
+#ifdef STATUS
+    sync_scoreboard_image();
+    for (i = 0; i<HARD_SERVER_LIMIT; ++i) {
+       rec = get_scoreboard_info(i);
+       if(rec.pid != my_pid) continue;
+       RETVAL = rec.my_access_count;
+       break;
+    }
+#else
     RETVAL = mod_perl_seqno();
+#endif
+
     CTRACE(stderr, "Apache%sseqno = %d\n", items ? "->" : "::", RETVAL);

     OUTPUT:

