#include <sys/event.h>
#include <sys/time.h> 
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h> 
#include <string.h>
#include <signal.h>
#include <unistd.h>

/* we want the signal handler to do nothing at all
 * since the kqueue system will handle it */
void sigint(int sig)
{
}


int main(int argc, char** argv) {
   int f, f2, kq, nev;

   signal(SIGINT, sigint);

   /* declare array of file descriptors */
   int *fds = (int *) malloc(argc-1 * sizeof(int));
   /* this looks weird.  the -1 is because argc includes the program name, and the +1 is
    * because we're actually adding our own process to the list to catch signals */
   struct kevent *changeList = (struct kevent *) malloc(argc-1+1 * sizeof(kevent));
   int eventListLen = 100;
   struct kevent eventList[100];

   kq = kqueue();
   if (kq == -1)
       perror("kqueue");

   int i;
   int pathCount = argc-1;

   /* add all paths on the command line */
   
   for (i=0; i < pathCount; i++) {
        printf("adding path %s\n", argv[i+1]);
        f = open(argv[i+1], O_RDONLY);
        if (f == -1) {
            perror("open");
            return;
        }
        EV_SET(&changeList[i], f, EVFILT_VNODE,
            EV_ADD | EV_ENABLE | EV_ONESHOT,
            NOTE_DELETE | NOTE_EXTEND | NOTE_WRITE | NOTE_ATTRIB,
            0, argv[i+1]);
    }
    

    EV_SET(&changeList[pathCount], SIGINT, EVFILT_SIGNAL,
            EV_ADD | EV_ENABLE | EV_ONESHOT,
            0, 0, "Process caught SIGINT");

    fflush(stdout);

    int done = 0;
    while(!done) {
        memset((void *)&eventList, 0x00, sizeof(eventList));
        nev = kevent(kq, changeList, pathCount+1, eventList, eventListLen, NULL); 
        if (nev == -1) {
            perror("kevent");
        }
        for (i=0; i < nev; i++) {
            if (eventList[i].flags & EV_ERROR) {
                printf("ERROR:in event %d\n", i);
                fflush(stdout);
            }
            if (eventList[i].ident == SIGINT) {
                printf("SIGNAL:SIGINT exitting...\n");
                fflush(stdout);
                done = 1;
                break;
            }
            if (eventList[i].fflags & NOTE_DELETE) {
                printf("DELETED:%s\n", eventList[i].udata);
                fflush(stdout);
            }
            if (eventList[i].fflags & NOTE_EXTEND || 
                eventList[i].fflags & NOTE_WRITE)
                printf("MODIFIED:%s\n", eventList[i].udata);
                fflush(stdout);
            if (eventList[i].fflags & NOTE_ATTRIB)
                printf("ATTRIBUTE_CHANGED:%s\n", eventList[i].udata);
                fflush(stdout);
        }
    }

    printf("freeing resources\n");
    /* close all file descriptors */
    for (i = 0; i < pathCount; i++) {
       close(fds[i]);
    }
    free(fds);

    close(kq);
    return EXIT_SUCCESS;
}
