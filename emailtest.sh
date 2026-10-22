#!/bin/bash

# Runs from a crontab to periodically send out a 'proof of life' email
#

scriptname="`basename $0`"
DEBUG=

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-d]" >&2
   echo "   -d          set debug flag"
   echo
}

# ===== function temp_sensor

function temp_sensor() {

    exitcode=1
    
    # read external temperature sensor DHT11 or DHT22
    if [ -e /etc/cpuinfo ] ; then
        # hack so Adafruit library can parse what hardware it's running
        # on
        sudo mount --bind /etc/cpuinfo /proc/cpuinfo

        temp_humid="$(/home/pi/my-venv/bin/python /home/pi/my-venv/dev/simpletest.py)"

        sudo umount /proc/cpuinfo

        degrees_celsius="$(echo $temp_humid | cut -d'=' -f2 | cut -d'*' -f1)"
        # debug
        # echo "degrees_celsius:$degrees_celsius"
        # $(echo "scale=2; $C * 9/5 + 32" | bc) to ensure precision.
	
        degrees_fahrenheit=$(echo "scale=2; $degrees_celsius * 9/5 + 32" | bc)

        # debug
        # echo "degrees_fahrenheit: $degrees_fahrenheit"
	exitcode=0
    fi
    return $exitcode 
}

# ==== Main

# MSGFILE="emailtemp.txt"
# Create a temporary file
MSGFILE=$(mktemp /tmp/$scriptname.XXXXXX)

# Is mutt installed?

type -P mutt &>/dev/null
if [ $? -ne 0 ] ; then
  echo "$scriptname: Need to Install mutt package"
  exit 1
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -d|--debug)
        DEBUG=1
        echo "Set debug flag"
        ;;
      *)
	echo "Unknown command line option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done

# is ax.25 support still in the kernel
#
# lsmod | grep -i ax25
# ls -l "/proc/net/ax25_calls"
# Check if kernel version is less than 7.1
# uname -r


subject="Test email from $(uname -n)"
target="basil@pacabunga.com"

if [ "$(uname -s)" = "Darwin" ]; then
    echo "Running on macOS"
fi

{
    # vcgencmd is Raspberry Pi only
    # convert to Fahrenheit, see dht11/dht11_temp.c
    # integer math,  f = ( (9 * celsius) + 160 ) / 5;
    c_temp="$(vcgencmd measure_temp | cut -d"=" -f2 | cut -d"'" -f1)"
    f_temp="$(echo $c_temp | cut -d'.' -f1)"
    f_temp_dec="$(echo $c_temp | cut -d'.' -f2)"

    if (( f_temp_dec >= 5 )) ; then
        ((f_temp++));
    fi
    f_temp=$(( ( 9 * f_temp +160 ) / 5 ));
    
    echo "$(date): CPU temp: $c_temp C, $f_temp F"
    temp_sensor
    retcode=$?
    # echo "DEBUG: temp_sensor ret code: $retcode"
    if [ $retcode -eq 0 ] ; then
        echo -n "Temp=$degrees_fahrenheit*F  "
        echo "$temp_humid"
    else
        echo "No temp sensor found"
    fi
    echo

    my_wlanip=$(ip a show | grep -i "inet " | grep -i "wlan0" | sed 's/^[[:space:]]*//' | cut -d ' ' -f2 | cut -d '/' -f1)
    my_lanip=$(ip route get 1.1 | awk '{print $7; exit}')
    external_ip=$(curl -s https://ifconfig.me)

    echo "Internal IP address: lan: $my_lanip, WiFi: $my_wlanip"
    echo "External IP address: $external_ip"
    echo
    echo "Running on: $(uname -s), ver: $(cat /etc/*version), kernel ver: $(uname -r)"
    echo "$($HOME/bin/piver.sh)"

    # Watchdog timer
    RSTS_REG=$(vcgencmd get_rsts)

    REBOOT_CNT=$(last reboot | grep ^reboot | wc -l)
    UP_TIME="$(uptime -p)"
    echo
    echo "=== RSTS: $RSTS_REG, reboot count: $REBOOT_CNT, $UP_TIME"
    
    rsts_val=$(echo $RSTS_REG | cut -d'=' -f 2)
    if [ "$rsts_val" == "1000" ] ; then
        echo "restart due to a power-on reset"
    elif [ "$rsts_val" == "20" ] ; then
        echo "restart due to a watchdog reset"
    else
        echo "Check these bits: -$rsts_val- for restart reason"
    fi
    echo
    last reboot | head -n 5

} > $MSGFILE

# Debug mode only display generated MSG file
if [ ! -z "$DEBUG" ] ; then
    cat "$MSGFILE"
else
    # Send an email using mutt & postfix
    mutt  -s "$subject" "$target" < "$MSGFILE"
    echo "mutt return: $?"
fi
