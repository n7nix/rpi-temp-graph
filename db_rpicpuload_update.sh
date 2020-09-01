#!/bin/bash

# RPi CPU temperatures

PATH=/usr/bin:/bin
MNTPNT="$HOME"
RRDDIR="$MNTPNT/var/lib/rpi/rrdtemp"	# Should be the same as RRDDIR in db_rpitempupupdate.sh
					# Where the RRD files will be stored. NO TRAILING SLASH
TMPDIR=$MNTPNT/var/tmp/rpitemp		# Where the png temp files will be stored. NO TRAILING SLASH

# Scripts to pull cpu load values
# Loadavg first 3 columns are last 1, 5 & 10 minute periods
# This gets the first arg, 1 minute load average period
#CPULOAD=$(/bin/cat /proc/loadavg | /bin/sed 's/^\([0-9\.]\+\) .*$/\1/g')
# This gets the 5 minute load average period
CPULOAD=$(cat /proc/loadavg | cut -f2 -d ' ')

##########################################################################################
################ EDIT THE FOLLOWING LINES TO MATCH YOUR CONFIGURATION ####################
##########################################################################################

UNIT=e 				# "m" for metric units or "e" for english units

WWWUSER=www-data		# The web server user
WWWGROUP=www-data		# The web server group

DEBUG=n				# Enable debug mode (y/n).
				# When debug mode is enabled, the DB's are not updated

CHOWN="chown"
CHMOD="chmod"
# Running as root?
if [ $EUID != 0 ] ; then
    CHOWN="sudo chown"
    CHMOD="sudo chmod"
fi

if [ ! -d "${TMPDIR}" ]; then
    mkdir -p ${TMPDIR}
    $CHOWN ${WWWUSER}:${WWWGROUP} ${TMPDIR}
    $CHMOD 777 ${TMPDIR}
fi

cd ${TMPDIR}

#CPULOAD1=$(${CPULOAD})

# Scale & truncate floating point number to make an integer
# May have to set scale first: echo 'scale=0; (l(101)/l(10)) / 1' | bc -l
CPULOAD1=$(echo "($CPULOAD * 100) / 1" | bc )

if [ ${DEBUG} = "y" ] ; then
    echo "Values found"
    echo "==============="
    echo "RPi CPU load    : ${CPULOAD1} : ${CPULOAD}"

else
    rrdtool update ${RRDDIR}/rpicpuload.rrd N:${CPULOAD1}
fi
