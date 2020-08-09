#!/bin/sh

# CBW read pump house temperatures

PATH=/usr/bin:/bin
user=$(whoami)
CBWTEMP=/home/$user/bin/cbw_gettemp.sh

##########################################################################################
################ EDIT THE FOLLOWING LINES TO MATCH YOUR CONFIGURATION ####################
##########################################################################################

UNIT=m 				# "m" for metric units or "e" for english units
TMPDIR=/var/tmp/cbwtemp		# Where the temp files will be stored. NO TRAILING SLASH
RRDDIR="/home/$user/var/lib/cbw/rrdtemp"	# This should be the same as RRDDIR in db_builder.sh
						# Where the RRD files will be stored. NO TRAILING SLASH
WWWUSER=www-data			# The web server user
WWWGROUP=www-data			# The web server group

DEBUG=n				# Enable debug mode (y/n).
				# When debug mode is enabled, the DB's are not updated

	if [ -d "${TMPDIR}" ];
		then
			cd ${TMPDIR}
		else
			mkdir ${TMPDIR}
			chown ${WWWUSER}:${WWWGROUP} ${TMPDIR}
			chmod 777 ${TMPDIR}
			cd ${TMPDIR}
	fi

	cd ${TMPDIR}

	TEMP1=$($CBWTEMP 1)
	TEMP2=$($CBWTEMP 2)
	TEMP3=$($CBWTEMP 3)	

		if [ ${DEBUG} = "y" ]
		   then
			echo "Values found"
			echo "==============="
			echo "Pump house high temperature    :" ${TEMP1}
			echo "Pump house outside temperature :" ${TEMP2}
			echo "Pump house low temperature     :" ${TEMP3}

		   else
			rrdtool update ${RRDDIR}/highpumphouse.rrd N:${TEMP1}
			rrdtool update ${RRDDIR}/outsidepumphouse.rrd N:${TEMP2}
			rrdtool update ${RRDDIR}/lowpumphouse.rrd N:${TEMP3}
		fi

