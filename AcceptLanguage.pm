# written by Rob Hartill <robh@imdb.com>
# Weeeeeeeeeeeeeee

package Apache::AcceptLanguage;
use Apache::Options;
use Apache::Constants;
use strict;

sub handler {
    my $r = shift;
    my $DEBUG = 0;

    # declare all the variables we intend using, so that's out of the way
    my ($i, $offset, $ext, $extensions, $best, @matching, $acceptables,
	$file, $dir, $len, $serve, %prefs);

    # take an early bath if there's nothing to do
    return DECLINED if 
	!($r->allow_options & OPT_MULTI)  # No Multiviews ? no point	
	    || !$r->is_main                      # a sub request
		|| -e $r->filename;                  # file exists

    # What extensions are we allowed to glue on to add and serve ?
    $extensions = $r->dir_config("AddOnExtensions");
    return DECLINED unless $extensions;  # Not allowed to add anything ?

    # Rip open the Accept-Language header and create a hash of
    #  lang=q  pairs for q>0 and where "lang" is in 'extensions' (allowed)

    foreach (split(/,/, $r->header_in("Accept-Language"))) {
	s/\s//g;  # strip spacing, leave only the interesting stuff
	if (m#;q=([\d\.]+)#) {
	    $prefs{$`}=$1 if $1 > 0 && index($extensions, $`)>=0;
	} else {
	    $prefs{$_}=1  if index($extensions, $_)>=0;
	}
    }
    # prepend the user's ordered prefs to the server's ordered prefs
    $extensions = 
	join(" ", sort {$prefs{$b} <=> $prefs{$a}} keys %prefs)
	    . " " . $extensions;

    # create a string list of extensions we accept ( | separated)
    ($acceptables = $extensions) =~ s/ /|/g;

    print STDERR "Serve Preferences = $extensions\n" if $DEBUG;

    # Open the directory containing the file
    ($dir = $r->filename) =~ s#[^/]*$##;
    $file = $&;
    return DECLINED if 
	$file eq "" || !opendir(DIR, $dir);  # nowt to wildcard match

    print STDERR "WILDCARDing ^$file(\\.($acceptables))+\$\n" if $DEBUG;
    # Grep out only files with allowed extensions that match the filename
    $len = length($file);   # +1 for the first \.

    @matching = map substr($_, $len+1),
    grep(/^$file(\.($acceptables))+$/, readdir(DIR));
    closedir(DIR);
    return DECLINED unless @matching;  # give up if nothing matches

    $best = 999;  # lowest scoring file wins. Start high
    $serve = 0;   # assume the first file is the winner

    for($i=0; $i <= $#matching; $i++) {
	print STDERR "Found file with extension(s): $matching[$i]\n" if $DEBUG;
	foreach $ext (split(/\./, $matching[$i])) {
	    # check the score (low = better) for each extension
	    $offset = index($extensions, $ext);
	    if ($offset < $best) {
		$best = $offset;
		$serve = $i;
		last if $best == 0; # it doesn't get any better
	    }
	}
	print STDERR " Best score so far = $best\n" if $DEBUG;
    }
    print STDERR "Best file was ".$r->filename.".$matching[$serve] with $best\n" if $DEBUG;

    # Tell Apache we have a new filename
    $r->filename("$dir$file.$matching[$serve]");
    # Give Apache the new files "stat" info
    $r->refresh_finfo;

    # Let other modules have their wicked way with the request.
    return DECLINED;
}

1;

__END__

Basically it works with Options 'Multiviews' and 

  PerlSetVar AddOnExtensions "en fr it de html"


This line tells the handler that give a request for "foo" that fails to
find a match, it is allowed to add on .en .fr  etc (and combinations
of them of course) to find a matching file.
The code looks for an "AcceptLanguage" header from the client to give some
languages a priority over others. So if I have

Accept-Language: en-gb;q=0.8, da, fr;q=0.9

then I prefer "Danish, French then 'British English'". If the server
doesn't have any of these, it goes through the allowed extensions and
picks whichever file contains the earliest match, so this forces ".en"
to be a default if there's nothing better, and we'll always be happy to
add on ".html", so ".en.html" is what I prefer people to default to if
they don't find a better preference.

The reason I wrote this is that mod_negotiation.c is HUGE and it doesn't
allow defaults, e.g. if a browser asks for Danish and we don't have any,
they get an error message (the behaviour is correct but unfriendly). I don't
know how HTTP kosher my algorithm is but it's better for all the MSIE
users with broken Accept-Language settings.


PerlTypeHandler Apache::AcceptLanguage


