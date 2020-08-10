#!/bin/bash
DEBUG=

# For raspberry pi with DHT11 temperature sensor
temp=$(ssh pi@10.0.42.37 bin/dht11_temp)
loopcnt=0

while [ -z "$temp" ] && [ $loopcnt -le 6 ]; do
    temp=$(ssh pi@10.0.42.37 bin/dht11_temp)
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
