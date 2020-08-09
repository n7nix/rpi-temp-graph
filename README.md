# rpi-temp-graph
Plot Raspberry Pi temperature on a graph using [RRD](https://oss.oetiker.ch/rrdtool/) logging & graphing tool

**Under development, NOT ready for use**

Temperature is read from the Raspberry Pi CPU using:
```
vcgencmd measure_temp
```
As an option a DHT11 temperature sensor for ambient temperature is also supported.
* DHT11 from [Sunfounder](https://www.sunfounder.com/humiture-sensor-module.html)
* DHT11 from [SongHe](https://www.amazon.com/gp/product/B07T7ZR7MS/ref=ppx_yo_dt_b_search_asin_title) sold on Amazon

### Intall RRDtool and Supporting Programs for Scripts

```
apt-get install rrdtool librrds-perl libxml-simple-perl
```

### Supporting scripts

##### rpicpu_gettemp.sh
* Used by db_rpitempupdate.sh to get current temperature(s)
##### db_rpitempbuilder.sh
* Used once at initial install to build first data base files
##### db_rpitempudpate.sh
* Called from crontab to update current temperature in RRD database


### Install instructions

* create directory RRDDIR ```/home/<user>/var/lib/cbw/rrdtemp```
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
cd /home/<user>/var/lib/cbw/
chown -R www-data:www-data rrdtemp
```

```
cd /var/www
chown -R www-data:www-data cgi-bin
```

##### Using spinning hard drive for data storage
* Add note about how often file system gets accessed
Changed RRDDIR data dir to ```/media/disk/rrd/var/lib/cbw/rrdtemp```
Was here: RRDDIR ```/home/<user>/var/lib/cbw/rrdtemp```

### Crontab

* crontab entry
```
*/5 *  * * *  /home/<user>/bin/db_cbwpumpupdate.sh
```
