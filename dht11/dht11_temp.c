/*
 * dht11_temp
 *
 * Program to read dht11 temperature sensor on a Raspberry Pi
 *
 * Command line argument: WiringPi pin number 0 - 31
 * default WiringPi gpio number is DHTPIN
 */

#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>

#define MAXTIMINGS 85
#define MAXCOUNTER 48  /* was 50, 16 */

/*
 * Use:  `gpio readall` to translate between WiringPi & BCM gpio pin numbers
 * Use:  `pinout` to get 40 pin header number
 *  WiringPi   BCM  PI 40 pin header  DRAWS 8 pin Aux
 *  --------   ---  ---------------   ---------------
 *     0       17        11              n/a
 *    21        5        29              3 (IO5)
 *    22        6        31              2 (IO6)
 */

#define DHTPIN 0

int dht11_dat[5] = {0,0,0,0,0};
int datacnt_total, datacnt_OK, datacnt_badnumbitsOK, datacnt_badnumbitslow;

#define PINLOW_PERIOD 18    /* Milliseconds */
#define PINHIGH_PERIOD 40   /* Microseconds */

/* Set DEBUG to 1 to turn on debug display */
#define DEBUG (0)
#define debug_print(fmt, ...) \
    do { if (DEBUG) fprintf(stderr, fmt, ##__VA_ARGS__); } while (0)

/*
 * Routine to pull data out of the dht11
 */
int read_dht11_dat(int gpiopin)
{
        uint8_t laststate = HIGH;
        uint8_t counter = 0;
        uint8_t j = 0, i;
        int retcode = 1; /* default to fail */

        dht11_dat[0] = dht11_dat[1] = dht11_dat[2] = dht11_dat[3] = dht11_dat[4] = 0;

        // pull pin down for 18 milliseconds
        pinMode(gpiopin, OUTPUT);
        digitalWrite(gpiopin, LOW);
        delay(PINLOW_PERIOD);
        // then pull it up for 40 microseconds
        digitalWrite(gpiopin, HIGH);
        delayMicroseconds(PINHIGH_PERIOD);
        /* prepare to read the pin */
        pinMode(gpiopin, INPUT);

        // detect change and read data
        for ( i=0; i< MAXTIMINGS; i++) {
                counter = 0;
                while (digitalRead(gpiopin) == laststate) {
                        counter++;
                        delayMicroseconds(1);
                        if (counter == 255) {
                                break;
                        }
                }
                laststate = digitalRead(gpiopin);
               /* printf( "%02x ", laststate); */
                if (counter == 255) {
                        break;
                }

                // ignore first 3 transitions
                if ((i >= 4) && (i%2 == 0)) {
                        // shove each bit into the storage bytes
                        dht11_dat[j/8] <<= 1;
                        if (counter > MAXCOUNTER)
                                dht11_dat[j/8] |= 1;
                        j++;
                }
        }

        datacnt_total++;
/*        printf("\n"); */
        // check we read 40 bits (8bit x 5 ) + verify checksum in the last byte
        // print it out if data is good
        if ((j >= 40) &&
            (dht11_dat[4] == ((dht11_dat[0] + dht11_dat[1] + dht11_dat[2] + dht11_dat[3]) & 0xFF)) ) {

#if 0
                {
                        float f; // fahrenheit

                        f = ((dht11_dat[2] * 9.0) / 5.0) + 32;
                        printf("Humidity = %d.%d %% Temperature = %d.%d *C (%.1f *F)\n",
                               dht11_dat[0], dht11_dat[1], dht11_dat[2], dht11_dat[3], f);
                }
#else
                {
                        int f;
                        int celsius=dht11_dat[2];
                        /* Round up conditioned on decimal value */
                        if (dht11_dat[3] >= 5) {
                                celsius++;
                        }
                /*
                 * F = (9/5) * Celsius + 32
                 *  = ( (9 * Celsius) / 5 ) + 32
                 *  = ( (9 * Celsius) / 5 ) + ( (32 * 5) / 5)
                 *  = ( (9 * Celsius) / 5 ) + ( 160 / 5)
                 */
                        f = ( (9 * celsius) + 160 ) / 5;
#if 0
                        printf("%d.%d, %d",
                               dht11_dat[2], dht11_dat[3], f);
#endif
                        printf("%d\n", f);
                }
#endif
                retcode=0;
        }
        return retcode;
}

/*
 * main
 */
int main (int argc, char **argv)
{
        int retcode=0;
        int gpiopin, gpiopin_use=DHTPIN;

        if (wiringPiSetup () == -1)
                exit (1) ;

        /*
         * Qualify GPIO pin number from command line arg if present
         */
        /* is there an arg? */
        if ( argc > 1 )  {
                int argbad=0;
                char *strptr;
                int i;

                /* get a pointer to command line arg */
                strptr=argv[1];
                /* iterate through all characters in arg */
                for(i = 0; strptr[i] != '\0'; i++) {
                        if ( isdigit(strptr[i]) == 0 ) {
                                debug_print( "Found BAD argument %s, using default WiringPi GPIO: %d\n", argv[1], gpiopin_use);
                                argbad=1;
                                break;
                        } else {
                                debug_print( "Found good argument %c\n", strptr[i]);
                        }
                }
                if (argbad == 0) {
                        gpiopin = atoi(strptr);
                        if ( gpiopin >= 0 && gpiopin < 32 ) {
                                gpiopin_use=gpiopin;
                        } else {
                                debug_print("Invalid gpio number: %d, using default WiringPI GPIO: %d\n", gpiopin, gpiopin_use);
                        }
                }
        } /* end if ( argc > 1 ) */
        else {
                debug_print("No arg, using default GPIO %d\n", gpiopin_use);
        }
        debug_print("Using GPIO %d\n", gpiopin_use);

        datacnt_total = datacnt_OK = datacnt_badnumbitsOK = datacnt_badnumbitslow = 0;

        retcode=read_dht11_dat(gpiopin_use);

        return retcode;
}
