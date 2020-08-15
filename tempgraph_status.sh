#!/bin/bash

scriptname="`basename $0`"
user="pi"
echo
echo "=== status start: $(date) ==="
echo
echo "=== lighttpd daemon status ==="
systemctl --no-pager status lighttpd

echo
echo "=== lighttphd enabled modules ==="
ls -1 /etc/lighttpd/conf-enabled/

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
