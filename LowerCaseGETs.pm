=pod

Message-ID:  <9709121500.AA32369@panama>
Date:         Fri, 12 Sep 1997 16:00:43 +0100
From: ccprl@PANAMA.PEGASUS.CRANFIELD.AC.UK
Subject:      A PerlTransHandler to lowercaseise URLs
Comments: cc: p.lister@cranfield.ac.uk
To: MODPERL@LISTPROC.ITRIBE.NET
X-UIDL: ab97f9b4b42307336e837d2268e8c3b5

OK, here's a simple, useful real world example of mod_perl.

We have found that mixed case URLs are a real support problem,
particularly wich C, P and other letters where the upper and lower
case are the same shape - people tend to pass around handwritten URLs
and sub-editors delight in corrupting them to "look nice". So we're
outlawing them on the University web server.

To keep all the existing refs working without a spaghetti of symlinks,
this handler relocates all mixed/upper case URLs to the lowercase
equivalent, This is (almost) transparent to the user, but much easier to
manager and means that bookmarks are set correctly. It ignores any URL
matching a pattern defined by the variable DoNotMolest, and will not
nuke queries.

=cut

package Apache::LowerCaseGETs ;
use Apache::Constants ':common' ;
$DEBUG_LOG = 0 ;
sub mywarn {
    my ( $r , $message ) = @ _ ;
    $r -> warn ( "[Apache::LowerCaseGETs] $message" ) if $DEBUG_LOG ;
}
#-----------------------------------------------------------------------
sub handler
{
    my $r = shift ( @_ ) ;
    &mywarn ( $r , "PerlTransHandler Start (" . $r->uri . ")" ) ;
    my $do_not_molest ;
    if ( $do_not_molest = $r -> dir_config ( 'DoNotMolest' ) )
    {
        if ( $r->uri=~m|$do_not_molest|i )
        {
            &mywarn ( $r , "Declining (URI matches DoNotMolest)" ) ;
            return DECLINED ;
        }
    }
    if ( $r -> method eq 'GET' )
    {
        # Make all GET URLs case insensitive by relocating them to the
        # lowercase equivalent. Redirects don't work with PUTs
        my $uri = $r -> uri ;
        if ( $uri=~m|[A-Z]| )
        {
            $uri=~tr/A-Z/a-z/ ;
            &mywarn ( $r , "TransHandler Converting URI " . $r->uri . " to $uri" ) ;
            $r -> uri ( $uri ) ;

            # If we have query arguments, remember to bolt them back
            # on before sending the redirect. Duhhh. Took me 3 hours to
            # work this one out...

            if ( $r-> args )
            {
                $uri = $uri . "?" . $r -> args ;
            }
            &mywarn ( $r , "Relocating to: $uri" ) ;
            $r->content_type ( "text/html" ) ;
            $r->header_out ( Location => $uri ) ;
            $r->header_out ( URI => $uri ) ;
            $r->status ( 301 ) ;
            return ( 301 ) ;
        }
    }
    &mywarn ( $r , "Declining (Method not GET)" ) ;
    return DECLINED ;
}
#-----------------------------------------------------------------------
1 ;

__END__

Peter Lister                             Email: p.lister@cranfield.ac.uk
Computer Centre, Cranfield University    Voice: +44 1234 754200 ext 2828
Cranfield, Bedfordshire MK43 0AL UK        Fax: +44 1234 751814
    I met a girl across the sea, her hair the gold that gold can be.
 Are you a teacher of the heart? Yes, but not for thee. (Leonard Cohen)


