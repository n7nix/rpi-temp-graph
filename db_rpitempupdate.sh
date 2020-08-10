#!/bin/sh

# RPi CPU temperatures

PATH=/usr/bin:/bin
MNTPNT="$HOME"
RRDDIR="$MNTPNT/var/lib/rpi/rrdtemp"	# Should be the same as RRDDIR in db_rpitempupupdate.sh
					# Where the RRD files will be stored. NO TRAILING SLASH
TMPDIR=$MNTPNT/var/tmp/rpitemp		# Where the png temp files will be stored. NO TRAILING SLASH

# Scripts to pull temperature values
RPITEMP=$HOME/bin/rpicpu_gettemp.sh
AMBTEMP=$HOME/bin/rpiamb_gettemp.sh

##########################################################################################
################ EDIT THE FOLLOWING LINES TO MATCH YOUR CONFIGURATION ####################
##########################################################################################

UNIT=e 				# "m" for metric units or "e" for english units


WWWUSER=www-data		# The web server user
WWWGROUP=www-data		# The web server group

DEBUG=y				# Enable debug mode (y/n).
				# When debug mode is enabled, the DB's are not updated

if [ ! -d "${TMPDIR}" ]; then
    mkdir -p ${TMPDIR}
    chown ${WWWUSER}:${WWWGROUP} ${TMPDIR}
    chmod 777 ${TMPDIR}
fi

cd ${TMPDIR}

RPITEMP1=$($RPITEMP)
AMBTEMP1=$($AMBTEMP)

if [ ${DEBUG} = "y" ] ; then
    echo "Values found"
    echo "==============="
    echo "RPi core temperature    : ${RPITEMP1}"
    echo "Ambient temperature     : ${AMBTEMP1}"
else
    rrdtool update ${RRDDIR}/rpicpu.rrd N:${RPITEMP1}
    rrdtool update ${RRDDIR}/rpiamb.rrd N:${AMBTEMP1}
fi

