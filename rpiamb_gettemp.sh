#!/bin/bash
# rpiamb_gettemp.sh
#
# Get value of ambient temperature in degrees Fahrenheit
# Calls dht11_temp C program to read DHT11 temperature sensor
#
# Any arguments on command line will set DEBUG flag
DEBUG=

# Set WiringPi GPIO pin number to use
#  Use:  `gpio readall` to translate between WiringPi & BCM gpio pin numbers
#  Use:  `pinout` to get 40 pin header number
#   WiringPi   BCM  PI 40 pin header  DRAWS 8 pin Aux
#   --------   ---  ---------------   ---------------
#      0        17        11              n/a
#     21         5        29              3 (IO5)
#     22         6        31              2 (IO6)

WIRINGPI_GPIO=0

# Can run this script remotely using ssh
# Need to create RSA keys so not prompted for password
REMOTE=false
IPADDR="10.0.42.37"

user=$(whoami)
# Check if there are any args on command line
if (( $# != 0 )) ; then
    DEBUG=1
fi

# Set command to use
if [ $REMOTE = true ] ; then
    # remote ambient temperature read
    getdht11_temp="ssh pi@${IPADDR} $HOME/bin/dht11_temp $WIRINGPI_GPIO"
else
    # local ambient temperature read
    getdht11_temp="/home/$user/bin/dht11_temp $WIRINGPI_GPIO"
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
