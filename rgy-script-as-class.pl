=pod

Message-ID:  <199703312213.RAA25121@postman.osf.org>
Date:         Mon, 31 Mar 1997 17:13:41 -0500
Reply-To: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
Sender: Discussion about the Apache ModPerl Module
              <MODPERL@LISTPROC.ITRIBE.NET>
From: Doug MacEachern <dougm@OPENGROUP.ORG>
Subject:      Re: inheritance in Apache::Registry?
Comments: To: Brian Slesinsky <bslesins@hotwired.com>
To: MODPERL@LISTPROC.ITRIBE.NET
In-Reply-To:  Your message of "Mon, 31 Mar 1997 11:59:49 EST." 
              <Pine.SOL.3.96.970331101839.24245A-100000@gossip.hotwired.com>
X-UIDL: f0f4c4d1efcd7a44829843db9cf578d2

Brian Slesinsky <bslesins@hotwired.com> wrote:

>
> On Mon, 31 Mar 1997, Doug MacEachern wrote:
>
> > I don't think you want to use Apache::Registry for this, the handler
> > class names are created on the fly, escaping the uri name until it's a
> > valid perl package name.  Your script moves, the class name changes.
>
> This doesn't really bother me.  Classes that are within htdocs probably
> shouldn't be called from outside Apache anyway, so I don't need
> to know their names.
>
> > We could call Perl*Handlers as methods.
>
> Hmm, that means I have to mess with the Apache config, rather than just
> creating a new file.
>
> So I tried making the changes myself, and it works, mostly.  Here are the
> changes:
>
[...]
>
> This works fine except that for some reason @ISA doesn't get used to look
> up the initial call to handler().  I had to add this line to my script:
>
>    sub handler { $_[0]->SUPER::handler; }
>
> Of course, there's a lot of duplicated code that should really be in one
> place.  Also, it would be nice if I could use both types of files in the
> same directory, depending on whether the file extension is .pl or .pm.
> But I can live with what I have.

okay, I think I have a better picture of what you want to do.  Look at
the example script I have below (using un-modified Apache::Registry).
It prints:

MyBase HEADER<hr>
<p>This is some text<p>
<hr>MyBase FOOTER

the uri is /perl/apache.pl, as you say, we don't care about our own
class name in this case, but we do setup the interitance tree.  In
this example we inherit from the `MyBase' package, which could also be
pulled in as a module.  The base class new(), header() and footer()
methods are inherited, but we implement our own body() method.  If
this is not what you are trying to do, please explain in greater
detail, example, etc.

-Doug

=cut 

use CGI ();
use strict;
use vars qw(@ISA);
@ISA = qw(MyBase);

my ($class) = @_;

my $page = $class->new;
my $q = CGI->new;

print $q->header, map { $page->$_() } qw(header body footer);

sub body {
    my($self) = @_;
    return "<p>This is some text<p>\n";
}

package MyBase;

sub new {
    my($class) = @_;
    bless {}, $class;
}

sub footer {
    "<hr>MyBase FOOTER\n";
}

sub header {
    "MyBase HEADER<hr>\n";
}

sub body {
      "MyBase BODY\n";
}

