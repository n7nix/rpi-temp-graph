# rpi-temp-graph
Plot Raspberry Pi temperature on a graph using RRD


### Intall RRDtool and Supporting Programs for Scripts

```
apt-get update
apt-get install rrdtool
apt-get install librrds-perl
apt-get install libxml-simple-perl
```

### Supporting scripts

##### rpicpu_gettemp.sh
##### db_rpitempbuilder.sh
##### db_rpitempudpate.sh
```

### Install instructions

* create directory RRDDIR /home/<user>/var/lib/cbw/rrdtemp
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
March 24, 2016
Changed RRDDIR data dir to /media/disk/rrd/var/lib/cbw/rrdtemp
Was here: RRDDIR /home/<user>/var/lib/cbw/rrdtemp

### Crontab

* crontab entry
```
*/5 *  * * *  /home/<user>/bin/db_cbwpumpupdate.sh
```
