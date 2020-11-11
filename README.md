# rpi-temp-graph
* Plot Raspberry Pi temperatures & CPU activity on a graph using:
  * [RRD](https://oss.oetiker.ch/rrdtool/) logging & graphing tool
  * [lighttpd](https://www.lighttpd.net/)
* If you install a DHT11 temperature sensor then both Raspberry Pi CPU &
ambient temperatures are plotted.

### Briefly
* Get this repo
```
git clone https://github.com/n7nix/rpi-temp-graph
```
* then run the install script
```
cd rpi-temp-graph
./tempgraph_install.sh
```
* verify install by running _tempgraph_status.sh_
```
./tempgraph_status.sh
```
* edit _rpiamb_gettemp.sh_ WIRINGPI_GPIO variable for GPIO used to read DHT11 module
```
cd
cd bin
nano rpiamb_gettemp.sh
```
* verify _rpiamb_gettemp.sh_ script returns a valid temperature
```
./rpiamb_gettemp.sh
```

* finally use your browser to view the graphs
```
url=http://localhost/cgi-bin/rpitemp.cgi
or if you want to view on a different computer
url=http://<some_ip_address>/cgi-bin/rpitemp.cgi
ie.
url=http://10.0.42.167/cgi-bin/rpitemp.cgi
```
* **NOTE: temperatures are read every 5 minutes so it may take a while to see
any data graphing**

### Raspberry Pi CPU Temperature
Temperature is read from the Raspberry Pi CPU using:
```
vcgencmd measure_temp
```
### Ambient Temperature
For ambient temperature, only the DHT11 temperature sensor is
supported. For both of these products a module is used & not the raw
sensor

* DHT11 from [Sunfounder](https://www.sunfounder.com/humiture-sensor-module.html)

* DHT11 from [SongHe](https://www.amazon.com/gp/product/B07T7ZR7MS/ref=ppx_yo_dt_b_search_asin_title) sold on Amazon
  * [DHT11 Temperature and Humidity Sensor Module](https://quartzcomponents.com/products/dht11-temperature-humidity-sensor-module)

**NOTE: Must edit** _rpiamb_gettemp.sh_ script variable WIRINGPI_GPIO in
directory ~/bin after install for the WIRINGP_GPIO pin number used
(0-31). Defaults to BCM GPIO 17 (WiringPi GPIO 0)
```
WIRINGPI_GPIO=
```
* Use console command:  _gpio readall_ to translate between WiringPi & BCM gpio pin numbers
* Use console command:  _pinout_ to get 40 pin header number


### Screen shot of temperature & CPU activity plots
* The RPi is running ardop on 80 Meters

![CPU & Ambient temperature plot](/images/rpitemp.cgi-1366x768.png)

### Images for Ambient temperature sensor install

##### Sunfounder DHT11 using Raspberry Pi 40 pin header and BCM GPIO 17
* Connects to 5V, GND and GPIO
  * RPi 40 pin header pin reference: Run program ```pinout``` in a console window on a
  Raspberry Pi.
![Sunfounder DHT11 on RPi](/images/img_2633_resize.jpg)

##### SongHe DHT11 using DRAWS hat AUX connectory and BCM GPIO 6

* Connects to 5V, GND and GPIO
  * DRAWS aux port pin reference: [DRAWS accessory
  connector](http://nwdigitalradio.com/wp-content/uploads/2020/08/DRAWSBrochure.pdf)
  - scroll down to see Accessory Connectory HDR-4x2M pinout

![SongHe DHT11 on RPi](/images/img_2630_resize.jpg)


### Supporting graph scripts

##### rpicpu_gettemp.sh
* Used by db_rpitempupdate.sh to get current temperature from CPU sensor
##### rpiamb_gettemp.sh
* Used by db_rpitempupdate.sh to get ambient temperature from dht11 device
##### db_rpitempudpate.sh
* Called from crontab to update current temperature in RRD databases
##### db_rpitempbuilder.sh
* Used once at initial install to build first data base files
##### amb_test.sh
* Verify that dht11 temperature sensor is returning reasonable
temperature values
  * Takes a WiringPi pin number as an argument
  * Default GPIO is WiringPi GPIO 0, (BCM GPIO 17)
```
./amb_test.sh 21
```

### Install instructions
* Use script: _tempgraph_install.sh_
* Verify with script: _tempgraph_status.sh_
* Use this url ```http://localhost/cgi-bin/rpitemp.cgi```
and wait for data to plotted

### Manual Install instructions

* The [install script tempgraph_install.sh](https://github.com/n7nix/rpi-temp-graph/blob/master/tempgraph_install.sh)
does all of the following and this description is only included here for reference.

### Install RRDtool and Supporting Programs

```
apt-get install rrdtool librrds-perl libxml-simple-perl lighttpd
```

* create directory RRDDIR ```/home/<user>/var/lib/rpi/rrdtemp```
* run db_rpitempbuilder.sh
* run db_rpitempupdate.sh as cron job every 5 min.
  * this calls script rpicpu_gettemp.sh

```
cp db_rpitempupdate.sh ~/bin
cp rpitemp.cgi /usr/lib/cgi-bin
check /var/www/cgi-bin
```
* setup owner group

```
cd /home/<user>/var/lib/rpi/
chown -R www-data:www-data rrdtemp
```

```
cd /var/www
chown -R www-data:www-data cgi-bin
```

##### Using spinning hard drive for data storage
* Add note about how often file system gets accessed
Changed RRDDIR data dir to ```/media/disk/rrd/var/lib/rpi/rrdtemp```
Was here: RRDDIR ```/home/<user>/var/lib/rpi/rrdtemp```

### Crontab

* crontab entry
```
*/5 *  * * *  /home/<user>/bin/db_rpitempupdate.sh
```
