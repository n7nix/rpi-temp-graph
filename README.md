# rpi-temp-graph
* Plot Raspberry Pi temperatures on a graph using:
  * [RRD](https://oss.oetiker.ch/rrdtool/) logging & graphing tool
  * [lighttpd](https://www.lighttpd.net/)
* If you install a DHT11 temperature sensor then both Raspberry Pi CPU &
ambient temperatures are plotted.
  * The external ambient temperature sensor for the plotting scripts
  to work, it's

### Briefly
* Get this repo
```
git clone https://github.com/n7nix/rpi-temp-graph
```
* then run the install script
```
cd rpit-temp-graph
./tempgraph_install.sh
```
* finally use your browser to view the graphs
```
url=http://localhost/cgi-bin/rpitemp.cgi
or if you want to view on a different computer
url=http://<some_ip_address>/cgi-bin/rpitemp.cgi
ie.
url=http://10.0.42.167/cgi-bin/rpitemp.cgi
```

### Raspberry Pi CPU temperature
Temperature is read from the Raspberry Pi CPU using:
```
vcgencmd measure_temp
```
### Ambient temperature
For ambient temperature, only the DHT11 temperature sensor is
supported. In both of these products I use a module & not the raw
sensor

* DHT11 from [Sunfounder](https://www.sunfounder.com/humiture-sensor-module.html)

* DHT11 from [SongHe](https://www.amazon.com/gp/product/B07T7ZR7MS/ref=ppx_yo_dt_b_search_asin_title) sold on Amazon
  * [DHT11 Temperature and Humidity Sensor Module](https://quartzcomponents.com/products/dht11-temperature-humidity-sensor-module)

### Screen shot of temperature plots

![CPU & Ambient temperature plot](/images/rpitemp.cgi-1366x768.png)

### Images for Ambient temperature sensor install

##### Sunfounder DHT11 using Raspberry Pi 40 pin header and BCM GPIO 17
* Connects to 5V, GND and GPIO
![Sunfounder DHT11 on RPi](/images/img_2633_resize.jpg)

##### SongHe DHT11 using DRAWS hat AUX connectory and BCM GPIO 6

* Connects to 5V, GND and GPIO

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


### Install instructions
* Use script: _tempgraph_install.sh_
* Verify with script: _tempgraph_status.sh_

### Manual Install instructions

* The [install script tempgraph_install.sh](https://github.com/n7nix/rpi-temp-graph/blob/master/tempgraph_install.sh)
does all of the following and this description is only included here for reference.

### Intall RRDtool and Supporting Programs for Scripts

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
