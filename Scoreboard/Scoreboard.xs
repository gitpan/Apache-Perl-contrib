#include "mod_perl.h"
#include "scoreboard.h"

#define MAX_PROC		40

MODULE = Apache::Scoreboard  PACKAGE = Apache::Scoreboard


#typedef struct {
#    pid_t pid;
#    char status;
##if defined(STATUS)
#    unsigned long access_count;
#    unsigned long bytes_served;
#    unsigned long my_access_count;
#    unsigned long my_bytes_served;
#    unsigned long conn_bytes;
#    unsigned short conn_count;
#    unsigned short how_long;
#    struct tms times;
#    time_t last_used;
#    char client[32];	/* Keep 'em small... */
#    char request[64];	/* We just want an idea... */
##endif
#} short_score;

void
image(CLASS="Apache::Scoreboard", score_name)
char *CLASS
char *score_name

  PPCODE:
{
    int i, score_fd;
    short_score rec;
    AV *av;
    HV *hv, *stash = gv_stashpv(CLASS, TRUE);
    if ((score_fd = open(score_name, 0)) == -1 ) {
	fprintf(stderr, "Can't open scoreboard file: %s\n", score_name);
	XSRETURN_UNDEF;
    }
    iniAV;
    for(i=0;i<MAX_PROC; i++) {
	read(score_fd, (char *)&rec, sizeof(short_score));
	if(rec.pid != 0) {
	    iniHV;
	    hv_store(hv, "pid", 3, newSViv((IV)rec.pid), 0); 
	    hv_store(hv, "status", 6, newSViv(rec.status), 0);
	    av_push(av, sv_bless(newRV((SV*)hv), stash));
	}
    }
    close(score_fd);
    XPUSHs(newRV((SV*)av));
    }

void
info(CLASS="Apache::Scoreboard",i)
char *CLASS
int i

    CODE:
    {
    #short_score rec = get_scoreboard_info(i);
    HV *hv = newHV(); 
    #STASH_SB_INFO;
    ST(0) = sv_2mortal(sv_bless( newRV((SV*)hv), gv_stashpv(CLASS,1) ));
    }




