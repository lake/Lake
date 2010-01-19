#include <sys/inotify.h>
#include <sys/queue.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>

/* This program will take as argument a number of path names and monitor them
   printing event notifications to the console.
*/
int main (int argc, char **argv)
{
    /* This is the file descriptor for the inotify device. */
    int inotify_fd = inotify_init ();
    if (inotify_fd < 0) {
        perror ("inotify_init");
        return 0;
    }
  
    int i, wd;
    /* Add each path passed on the command line.  We want to be notified
     * if a file is modified, created, or its attribute changes (like mtime)
     */
    for (i=1; i < argc; i++) {
        wd = inotify_add_watch(inotify_fd, argv[i],
            IN_MODIFY | IN_CREATE | IN_ATTRIB);
        if (wd < 0) {
            perror("inotify_add_watch");
            return 0;
        }
    }

    /* size of the event structure, not counting name */
    #define EVENT_SIZE  (sizeof (struct inotify_event))

    /* reasonable guess as to size of 1024 events */
    #define BUF_LEN        (1024 * (EVENT_SIZE + 16))

    char buf[BUF_LEN];
    int len;
    while (1) {
        len = read(inotify_fd, buf, BUF_LEN);
        if (len < 0) {
            if (errno == EINTR) {
                /* need to reissue system call */
                continue;
            } else {
                /* don't actuall fail on the read, just try to
                 * re-read */
                perror("read");
                continue;
            }
        } 
    
        /* read all of the events */
        struct inotify_event *event;
        for(i=0; i < len; i += EVENT_SIZE + event->len) {
            event = (struct inotify_event *) &buf[i];
            if (event->len) 
                printf("CHANGE_EVENT:%s\n", event->name);
            else
                printf("CHANGE_EVENT:\n");
            fflush(stdout);
        }
    }
    
    close(inotify_fd);
    return EXIT_SUCCESS;
}
