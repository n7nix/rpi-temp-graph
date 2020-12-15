#!/bin/bash
# rpiamb_gettemp.sh
#
# Get value of ambient temperature in degrees Fahrenheit
# Calls dht11_temp C program to read DHT11 temperature sensor
#
# NEED TO EDIT WiringPi GPIO pin number to use
#  Use:  `gpio readall` to translate between WiringPi & BCM gpio pin numbers
#  Use:  `pinout` to get 40 pin header number
#   WiringPi   BCM  PI 40 pin header  DRAWS 8 pin Aux
#   --------   ---  ---------------   ---------------
#      0        17        11              n/a
#     21         5        29              3 (IO5)
#     22         6        31              2 (IO6)
#
# A -d argument on command line will set DEBUG flag
DEBUG=

WIRINGPI_GPIO=0
# Can run this script remotely using ssh
# Need to create RSA keys so not prompted for password
REMOTE=false
IPADDR="10.0.42.37"

# Set default temperature units to Fahrenheit
unit="F"

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

user=$(whoami)

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

# Set either remote or local command to use
if [ $REMOTE = true ] ; then
    # remote ambient temperature read
    getdht11_temp="ssh pi@${IPADDR} $HOME/bin/dht11_temp -g $WIRINGPI_GPIO -u $unit"
else
    # local ambient temperature read
    getdht11_temp="/home/$user/bin/dht11_temp -g $WIRINGPI_GPIO -u $unit"
fi

# Read the temperature sensor
temp=$($getdht11_temp)

# Loop until some value is read
loopcnt=0
while [ -z "$temp" ] && [ $loopcnt -le 6 ]; do
    sleep .5
    temp=$($getdht11_temp)
    ((loopcnt++))
done

if [ -z "$temp" ] ; then
    echo "Error temp: $temp"
fi

if [ ! -z "$DEBUG" ] ; then
    echo "$temp, cnt: $loopcnt"
else
    echo "$temp"
fi
