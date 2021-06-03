#!/bin/bash

# RRD builder for RPi CPU load average graph

PATH=/usr/bin:/bin

MNTPNT="$HOME"
RRDDIR="$MNTPNT/var/lib/rpi/rrdtemp"	# This should be the same as RRDDIR in db_rpitempupupdate.sh

#######################################################################################
### YOU SHOULD NOT HAVE TO EDIT ANYTHING BELOW THIS LINE ##############################
#######################################################################################

# ===== prompt to build data base files
function prompt_build_db() {

    echo "Are you sure you want to create the database files ?"
    echo -n "IT WILL OVERWRITE EXISTING DATA (y/n) "
    read ANSWER
    echo ""
}

# ===== main

#clear

echo ""
echo "RRDrpi : CPU load database builder"
echo "-----------------------------"

# Default to overwriting any existing database files
ANSWER="y"

# If any command line args do not prompt, just over write files.
# - for unattended initial install
if [ "$#" -eq 0 ] ; then
    # sets variable ANSWER to y or n
    prompt_build_db
fi

#        --step 60 \
#	--start ${TIMESEC}-1000 \
#	--start 1127253600 \

if [ ${ANSWER} = "n" ] ; then

	echo " "
	echo "Exiting..."
	echo " "
	exit 0

elif [ ${ANSWER} = "y" ] ; then

        # Time in seconds since 1970
        TIMESEC=$(date "+%s")

	cd

	if [ ! -d ${RRDDIR} ] ; then
            mkdir -p ${RRDDIR}
	fi

	rrdtool create ${RRDDIR}/rpicpuload.rrd \
	--start now-10s \
        --step 60 \
	DS:loadavg:GAUGE:120:0:10000 \
	RRA:AVERAGE:0.5:1:1500 \
	RRA:AVERAGE:0.5:6:1600 \
	RRA:AVERAGE:0.5:24:1675 \
	RRA:AVERAGE:0.5:288:1700 \
	RRA:MIN:0.5:1:1500 \
        RRA:MIN:0.5:6:1600 \
        RRA:MIN:0.5:24:1675 \
        RRA:MIN:0.5:288:1700 \
	RRA:MAX:0.5:1:1500 \
        RRA:MAX:0.5:6:1600 \
        RRA:MAX:0.5:24:1675 \
        RRA:MAX:0.5:288:1700

	echo ""
	echo "Database files built..."
	echo ""
	echo "Listing database files created under ${RRDDIR} :"
	ls -lh ${RRDDIR}/
	echo ""
	echo "Now, you can setup the db_rpicpuload_update.sh script and a crontab entry to run it"

else
	echo " "
	echo " y or n only!"
	echo "Exiting..."
	echo ""
	exit 1
fi
