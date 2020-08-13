/*
 * Build like this:
 * gcc humiture.c -lwiringPi
 *
 */

#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define MAXTIMINGS 85
#define MAXCOUNTER 48  /* was 50, 16 */

#define DHTPIN 0

int dht11_dat[5] = {0,0,0,0,0};
int datacnt_total, datacnt_OK, datacnt_badnumbitsOK, datacnt_badnumbitslow;

#define PINLOW_PERIOD 18    /* Milliseconds */
#define PINHIGH_PERIOD 40   /* Microseconds */

int read_dht11_dat()
{
        uint8_t laststate = HIGH;
        uint8_t counter = 0;
        uint8_t j = 0, i;
        int retcode = 1; /* default to fail */

        dht11_dat[0] = dht11_dat[1] = dht11_dat[2] = dht11_dat[3] = dht11_dat[4] = 0;


        // pull pin down for 18 milliseconds
        pinMode(DHTPIN, OUTPUT);
        digitalWrite(DHTPIN, LOW);
        delay(PINLOW_PERIOD);
        // then pull it up for 40 microseconds
        digitalWrite(DHTPIN, HIGH);
        delayMicroseconds(PINHIGH_PERIOD);
        /* prepare to read the pin */
        pinMode(DHTPIN, INPUT);

        // detect change and read data
        for ( i=0; i< MAXTIMINGS; i++) {
                counter = 0;
                while (digitalRead(DHTPIN) == laststate) {
                        counter++;
                        delayMicroseconds(1);
                        if (counter == 255) {
                                break;
                        }
                }
                laststate = digitalRead(DHTPIN);
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

int main (void)
{
        int retcode=0;

        if (wiringPiSetup () == -1)
                exit (1) ;

        datacnt_total = datacnt_OK = datacnt_badnumbitsOK = datacnt_badnumbitslow = 0;

        retcode=read_dht11_dat();

        return retcode;
}
