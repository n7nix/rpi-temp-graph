#!/bin/bash
DEBUG=
REMOTE=false
# local ambient temperature read
getdht11_temp=$HOME/bin/dht11_temp

# Check if there are any args on command line
if (( $# != 0 )) ; then
    DEBUG=1
fi

if [ $REMOTE = true ] ; then
    # remote ambient temperature read
    getdht11_temp="ssh pi@10.0.42.37 bin/dht11_temp"
fi

# For raspberry pi with DHT11 temperature sensor
temp=$($getdht11_temp)
loopcnt=0

while [ -z "$temp" ] && [ $loopcnt -le 6 ]; do
    temp=$($getdht11temp)
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
