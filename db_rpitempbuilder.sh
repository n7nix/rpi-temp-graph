#!/bin/bash

# RRD builder for RPi CPU temperature graph

PATH=/usr/bin:/bin

MNTPNT="$HOME"
RRDDIR="$MNTPNT/var/lib/rpi/rrdtemp"	# This should be the same as RRDDIR in db_rpitempupupdate.sh

#######################################################################################
### YOU SHOULD NOT HAVE TO EDIT ANYTHING BELOW THIS LINE ##############################
#######################################################################################

clear

echo ""
echo "RRDrpi : database builder"
echo "-----------------------------"
echo "Are you sure you want to create the database files ?"
echo -n "IT WILL OVERWRITE EXISTING DATA (y/n) "
read ANSWER
echo ""


if [ ${ANSWER} = "n" ]
then
	echo " "
	echo "Exiting..."
	echo " "
	exit 0

elif [ ${ANSWER} = "y" ]
then

	cd

	if [ ! -d ${RRDDIR} ]
	then
		mkdir -p ${RRDDIR}
	fi

	rrdtool create ${RRDDIR}/rpicpu.rrd \
	--start now-10s \
	DS:cpu:GAUGE:600:-50:150 \
	RRA:AVERAGE:0.5:1:600 \
	RRA:AVERAGE:0.5:6:700 \
	RRA:AVERAGE:0.5:24:775 \
	RRA:AVERAGE:0.5:288:797 \
	RRA:MIN:0.5:1:600 \
        RRA:MIN:0.5:6:700 \
        RRA:MIN:0.5:24:775 \
        RRA:MIN:0.5:288:797 \
	RRA:MAX:0.5:1:600 \
        RRA:MAX:0.5:6:700 \
        RRA:MAX:0.5:24:775 \
        RRA:MAX:0.5:288:797

	rrdtool create ${RRDDIR}/rpiamb.rrd \
        --start now-10s \
        DS:ambient:GAUGE:600:-50:150 \
        RRA:AVERAGE:0.5:1:600 \
        RRA:AVERAGE:0.5:6:700 \
        RRA:AVERAGE:0.5:24:775 \
        RRA:AVERAGE:0.5:288:797 \
        RRA:MIN:0.5:1:600 \
        RRA:MIN:0.5:6:700 \
        RRA:MIN:0.5:24:775 \
        RRA:MIN:0.5:288:797 \
        RRA:MAX:0.5:1:600 \
        RRA:MAX:0.5:6:700 \
        RRA:MAX:0.5:24:775 \
        RRA:MAX:0.5:288:797

	echo ""
	echo "Database files built..."
	echo ""
	echo "Listing database files created under ${RRDDIR} :"
	ls -lh ${RRDDIR}/
	echo ""
	echo "Now, you can setup the db_rpitempupdate.sh script and a crontab entry to run it"

else

	echo " "
	echo " y or n only!"
	echo "Exiting..."
	echo ""
	exit 1

fi
