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


void read_dht11_dat()
{
	uint8_t laststate = HIGH;
	uint8_t counter = 0;
	uint8_t j = 0, i;
        float f; // fahrenheit

        dht11_dat[0] = dht11_dat[1] = dht11_dat[2] = dht11_dat[3] = dht11_dat[4] = 0;


	// pull pin down for 18 milliseconds
	pinMode(DHTPIN, OUTPUT);
	digitalWrite(DHTPIN, LOW);
	delay(18);
	// then pull it up for 40 microseconds
	digitalWrite(DHTPIN, HIGH);
	delayMicroseconds(40);
	// prepare to read the pin
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
		if (counter == 255) break;

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
                datacnt_OK++;
		f = ((dht11_dat[2] * 9.0) / 5.0) + 32;
		printf("Humidity = %d.%d %% Temperature = %d.%d *C (%.1f *F)\n",
				dht11_dat[0], dht11_dat[1], dht11_dat[2], dht11_dat[3], f);
	}
	else {
                if ( j >= 40) {
                        datacnt_badnumbitsOK++;
                } else {
                        datacnt_badnumbitslow++;
                }
                printf("Data not good, bits: %d, skip: total: %d, OK: %d (%d%%), bad: %d, bad # bits: %d\n", j,
                      datacnt_total, datacnt_OK, (datacnt_OK*100/datacnt_total),datacnt_badnumbitsOK, datacnt_badnumbitslow);

                printf("Data: 0: %d, 1: %d, 2: %d, 3: %d, 4: %d\n",
                        dht11_dat[0], dht11_dat[1], dht11_dat[2], dht11_dat[3], dht11_dat[4]);
	}
}

int main (void)
{

	printf ("Raspberry Pi wiringPi DHT11 Temperature test program\n") ;

	if (wiringPiSetup () == -1)
		exit (1) ;

        datacnt_total = datacnt_OK = datacnt_badnumbitsOK = datacnt_badnumbitslow = 0;

	while (1)
	{
		read_dht11_dat();
		delay(1000); // wait 1sec to refresh
	}

	return 0 ;
}
