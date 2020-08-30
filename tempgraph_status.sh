#!/bin/bash
#
DEBUG=

scriptname="`basename $0`"

# Set debug flag if any args on command line
if (( $# != 0 )) ; then
    DEBUG=1
fi

echo
echo "=== status start: $(date) ==="
echo
echo "=== CPU & Ambient sensor check ==="

program_name="rpicpu_gettemp.sh"
# type command will return 0 if program is installed
type -P "$program_name" &>/dev/null
if [ $? -ne 0 ] ; then
   echo "Script: $program_name not installed"
else
   echo "Temp $program_name: $($program_name)"
fi

program_name="rpiamb_gettemp.sh"
# type command will return 0 if program is installed
type -P "$program_name" &>/dev/null
if [ $? -ne 0 ] ; then
   echo "Script: $program_name not installed"
else
   echo "Temp $program_name: $($program_name)"
fi

# Get lighttpd daemon status
systemctl --no-pager status lighttpd > /dev/null 2>&1
retcode="$?"
if [ "$retcode" -eq 0 ] ; then
    lighty_status="OK"
else
    lighty_status="FAILED: $retcode"
fi

echo
echo "=== lighttpd daemon status $lighty_status ==="

# if debug flag is set display all of lighttpd status
if [ ! -z "$DEBUG" ] ; then
    systemctl --no-pager status lighttpd
fi

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
echo "=== png file check ==="
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
