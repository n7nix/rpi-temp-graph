#!/bin/bash
#
# amb_test.sh
# Continuously read the dht11 temperature module displaying,
# temperature, loop cnt to get a valid read, total pass count
#
# Example:
# ./amb_test.sh 21
#
# Set WiringPi GPIO pin number to use
#  Use:  `gpio readall` to translate between WiringPi & BCM gpio pin numbers
#  Use:  `pinout` to get 40 pin header number
#   WiringPi   BCM  PI 40 pin header  DRAWS 8 pin Aux
#   --------   ---  ---------------   ---------------
#      0        17        11              n/a
#     21         5        29              3 (IO5)
#     22         6        31              2 (IO6)
#
# Set DEBUG=1 for verbose output
DEBUG=

WIRINGPI_GPIO=0

REMOTE=false
IPADDRESS="10.0.42.37"

# Test duration in seconds
test_time=$((60*5))

user=$(whoami)

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_integer

function is_integer() {
#    [ "$1" -eq "$1" ] > /dev/null 2>&1
    [[ $1 =~ ^-?[0-9]+$ ]]
    return $?
}

# ===== function gettemp
# For raspberry pi with DHT11 temperature sensor

function gettemp() {
    temp=$($getdht11_temp)
#    temp=$(/home/$user/bin/dht11_temp)
    loopcnt=0

    while [ -z "$temp" ] && [ $loopcnt -le 8 ]; do
        sleep .5
        temp=$($getdht11_temp)
        ((loopcnt++))
    done

    if [ -z "$temp" ] ; then
        echo "Error : $loopcnt"
        ((errorcnt++))
    else
        printf "%d : %d : %d    \r" "$temp" "$loopcnt" "$callcnt"
    fi
}

# ===== main

# Check if there are any args on command line and if it is numeric
if (( $# != 0 )) ; then
    echo "Verify arg: $1 is an integer"
    is_integer $1
    if [ $? = 0 ] ; then
        WIRINGPI_GPIO=$1
    else
        echo "Argument: $1 is not an integer"
    fi
fi
echo "Using GPIO number: $WIRINGPI_GPIO"

# local ambient temperature read
getdht11_temp="/home/$user/bin/dht11_temp -g $WIRINGPI_GPIO"

if [ $REMOTE = true ] ; then
    # remote ambient temperature read
    getdht11_temp="ssh pi@${IPADDRESS} $HOME/bin/dht11_temp -g $WIRINGPI_GPIO"
fi

callcnt=0
errorcnt=0
start_sec=$SECONDS
duration=$((SECONDS-start_sec))

while [ $duration -le $test_time ] ; do
    gettemp
    duration=$((SECONDS-start_sec))
    ((callcnt++))
    sleep 1
done

echo
echo "Error count: $errorcnt"
