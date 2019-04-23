/*
 *
 * Original source from here:
 * testGpsPort.c
 * https://gist.github.com/paingineer/5f23b02282553782ceec
 *
 * and
 *
 * http://bradsmc.blogspot.com/2013/11/c-code-to-read-gps-data-via-serial-on.html
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>

const char* GPS_PORT_NAME = "/dev/ttySC0";

int testResult = 0;
int fd;

#define GP_SUCCESS 0
#define GP_FAILED_EXEC 1
#define GP_ERROR_GETTING_GPSCOM_ATTR 2
#define GP_ERROR_SETTING_GPSCOM_ATTR 3
#define GP_ERROR_OPENING_GPSCOM 4

int err = GP_FAILED_EXEC;

static void usage(char *progname);
const char *getprogname(void);

extern char *__progname;

int gp_baudrate = B9600; /* nope: B4800 */
bool bVerbose=false;

int main(int argc, char *argv[])
{
        int opt;
        extern int optind;
        extern char *optarg;
        int n, cnt, satcnt;
        char *pch, *ptr;
        struct termios oldtio, newtio;

     /*
      *  parse the command line options
      */
        while ((opt = getopt(argc, argv, "vh")) != -1) {
                switch (opt) {
                        case 'v': /* set verbose mode */
                                bVerbose=true;
                                break;
                        case 'h': /* help */
                                usage(argv[0]);
                                exit(0);
                                break;
                        case '?':
                        default:
                                printf("ERROR: invalid option usage");
                                usage(argv[0]);
                                /*NOTREACHED*/
                                exit(2);
                }
        }



        fd = open(GPS_PORT_NAME, O_RDWR | O_NOCTTY);
        if (fd < 0) {
                perror(GPS_PORT_NAME); exit(GP_ERROR_OPENING_GPSCOM);
        }

        if ((tcgetattr(fd, &oldtio)) == -1) {
                perror("tcgetattr()");
                exit(GP_ERROR_GETTING_GPSCOM_ATTR);
        }

        bzero(&newtio, sizeof(newtio)); /* clear struct for new port settings */
        newtio.c_cflag = gp_baudrate | CRTSCTS | CS8 | CLOCAL | CREAD;

        /* IGNPAR  : ignore bytes with parity errors
        otherwise make device raw (no other input processing) */
        newtio.c_iflag = IGNPAR;

        /*  Raw output  */
        newtio.c_oflag = 0;

        /* ICANON  : enable canonical input
        disable all echo functionality, and don't send signals to calling program */
        newtio.c_lflag = ICANON;

        /* clean the modem line and activate settings for the port */
        tcflush(fd, TCIOFLUSH); // Flush the previously buffered data

        if ((tcsetattr(fd, TCSANOW, &newtio)) == -1) {
                perror("tcgetattr()");
                exit(GP_ERROR_SETTING_GPSCOM_ATTR);
        }
        /*         tcsetattr(fd,TCSANOW,&newtio); */

        /* NMEA command to ouput all sentences */
        n = write(fd, "$PTNLSNM,273F,01*27\r\n", 21);

        /* terminal settings done, now handle input*/

        err = GP_SUCCESS;

        char buf [256];
        memset(buf, 256, (size_t)0);

        while (true) {     /* loop continuously */
#if 0
                sleep(1); // Wait for at least 1 PPS
#endif
                n = read (fd, buf, sizeof buf);
                buf[n] = 0;             /* set end of string, so we can printf */
                if( n > 0 ) {
                        if(bVerbose) {
                                // Find a $GP string coming from the gps
                                pch = strstr(buf ,"$GP");

                                if( pch != NULL ){
                                        testResult = 1;
                                        printf ("GP: %s", buf);
                                } else {
                                        printf (" %s", buf);
                                }
                        }
                        // Find a $GNGGA string coming from the gps
                        pch = strstr(buf ,"$GNGGA");
                        if( pch != NULL ){
                                testResult = 1;
                                if(bVerbose) {
                                        printf ("GGA: %s", buf);
                                }
                                strtok(buf,",");
                                ptr=buf;
                                cnt=0;
                                while( ptr != NULL && cnt < 7) {
                                        ptr = strtok(NULL, ",");
                                        cnt++;
                                }
                                satcnt=atoi(ptr);
                                if(bVerbose) {
                                        printf("sats: %d\n", satcnt);
                                } else {
                                        printf("sats: %d\r", satcnt);
                                        fflush(stdout);
                                }

                                if(satcnt == 0) {
                                        printf("Warning sat count is 0\n");
                                }
                        }
                }
        }
        tcsetattr(fd, TCSANOW, &oldtio);
        close(fd);
        return err;
}

const char *getprogname(void)
{
        return __progname;
}

/*
 * Print usage information and exit
 *  -does not return
 */
static void
   usage(char *progname)
{
        printf("Usage: %s [options]\n", progname);
        printf("  -h    Display this usage info\n");
        printf("  -v    Set verbose mode\n");
        exit(0);
}
