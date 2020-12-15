#!/bin/bash
#
# A -d argument on command line will set DEBUG flag
DEBUG=

# Can run this script remotely using ssh
# Need to create RSA keys so not prompted for password
REMOTE=false
IPADDR="10.0.42.37"

# Specify default temperature units
unit="F"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Display program help info
#
usage () {
    (
    echo "Usage: $scriptname [-u <c|f>][-d][-h]"
    echo "   -u <unit>    Specify temperature units, either c (Celsius) or f (Fahrenheit)"
    echo "   -d           Set DEBUG flag"
    echo "   -h           Display this message."
    echo
    ) 1>&2
    exit 1
}

# ===== main

# Check if there are any args on command line
while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -u|--unit)
      unit="$2"
      # Conver to upper case
      unit=$(echo "$unit" | tr '[a-z]' '[A-Z]')
      if [ $unit != 'C' ] && [ $unit != 'F' ] ; then
          echo "Invalid unit argument: $unit, default to Fahrenheit"
	  unit = "F"
      fi
      shift # past argument
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

# local cpu temperature read command
getcpu_temp="/usr/bin/vcgencmd measure_temp"

# Set either remote or local command to use
if [ $REMOTE = true ] ; then
    # remote cpu temperature read command
    getcpu_temp="ssh pi@${IPADDR} '/usr/bin/vcgencmd measure_temp'"
fi

temp=$($getcpu_temp | cut -f2 -d'=' | cut -f1 -d"'")
temp_int=$(echo $temp | cut -f1 -d'.')
temp_dec=$(echo $temp | cut -f2 -d'.')

# Check if any thing was read from getcpu_temp
if [ ! -z "$temp" ] ; then
    if [ $unit = "F" ] ; then
        dbgecho "Compute Fahrenheit: $temp_int C"
        if ((temp_dec >= 5)) ; then
            ((temp_int++))
            dbgecho "Bump temp_int"
        fi
        temp_fah=$(( ((9 * temp_int)+160)/5 ))
        temp_fah1=$(( ((9 * temp_int)/5)+32 ))

        if [ ! -z "$DEBUG" ] ; then
            echo "Temp raw: $temp, int: $temp_int, dec: $temp_dec, fah: $temp_fah, fah1: $temp_fah1"
        else
            echo "$temp_fah"
        fi
    elif [ $unit = "C" ] ; then
        echo "$temp"
    else
        echo "Invalid temperature units $unit"
    fi
else
    echo "Error temp: $temp"
fi
