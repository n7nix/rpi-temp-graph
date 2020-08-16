#!/bin/bash

scriptname="`basename $0`"

echo
echo "=== status start: $(date) ==="
echo
echo "=== lighttpd daemon status ==="
systemctl --no-pager status lighttpd

echo
echo "=== lighttphd enabled modules ==="
ls -1 /etc/lighttpd/conf-enabled/

echo
echo "=== lighttpd document root ==="
grep -i "document-root" /etc/lighttpd/lighttpd.conf

echo
echo "=== Web page check ==="
curl -I "http://localhost/cgi-bin/rpitemp.cgi" 2>&1 | grep -w "200\|301"
if [ $? -eq 0 ] ; then
    result="UP"
else
    result="DOWN"
fi
echo "RPi temp webpage is $result"

echo
echo "=== rrd file check ==="
ls -al ~/var/lib/rpi/rrdtemp
echo
ls -al ~/var/tmp/rpitemp

echo
echo "=== crontab check ==="
crontab -l | grep -i "db_rpitempupdate.sh"
if [ $? -eq 0 ] ; then
    result="OK"
else
    result="MISSING"
fi
echo "Crontab entery is $result"
