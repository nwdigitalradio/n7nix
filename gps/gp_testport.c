/*
 * gp_testport.c
 *
 * Read GPS serial port in a loop reading xxGGA sentence for number of
 * satellites in view. Display current, min, max satellite count.
 *
 * Call from gps_test.sh script to stop gpsd, trap ctrl_c & start gpsd
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
#include <time.h>

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
void min_check(int, int *);
void print_date(time_t timet);

extern char *__progname;

int gp_baudrate = B9600; /* nope: B4800 */
bool bVerbose=false;
time_t start_sec;
#define elapsed_sec_check (2*60)
bool b_onetimeflag = false;

int main(int argc, char *argv[])
{
    int opt;
    extern int optind;
    extern char *optarg;
    int n, cnt;
    int satcnt, min_satcnt, max_satcnt;
    char *pch, *ptr;
    struct termios oldtio, newtio;
    char buf [256]; /* buffer for serial port read */

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

    memset(buf, sizeof buf, (size_t)0);

    /* Read current time of day */
    start_sec = time(NULL);
    print_date(start_sec);

    /* initialize sat counts */
    min_satcnt=max_satcnt = 0;

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

                if ( satcnt > max_satcnt ) {
                    max_satcnt = satcnt;
                }
                min_check(satcnt, &min_satcnt);

                if(bVerbose) {
                    printf("sats: %d, min: %d, max: %d\n",
                           satcnt, min_satcnt, max_satcnt);
                } else {
                    printf("sats: %d, min: %d, max: %d\r",
                           satcnt, min_satcnt, max_satcnt);
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

void min_check(int satcnt, int *min_satcnt)
{
    time_t current_sec = time(NULL);

    /* wait about 2 minutes before reading satellites */
    if ( ! b_onetimeflag && (current_sec - start_sec > elapsed_sec_check)) {
        /* if the sat count is zero from the get go then some thing is
         * wrong
         */
        if ( satcnt > 0 ) {
/*    debug putchar('\n'); */
/*    debug print_date(current_sec); */
            b_onetimeflag = true;
            *min_satcnt = satcnt;
        }
    } else {
        if ( satcnt < *min_satcnt ) {
            *min_satcnt = satcnt;
        }
    }
}

void print_date(time_t timet) {

    struct tm *tm = localtime(&timet);
    char s[64];
    strftime(s, sizeof(s), "%c", tm);
    /* for debug: printf("%s\n", s); */
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
