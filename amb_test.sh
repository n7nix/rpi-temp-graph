#!/bin/bash

# Test duration in seconds
test_time=$((60*10))
DEBUG=
REMOTE=false
user=$(whoami)
# local ambient temperature read
getdht11_temp="/home/$user/bin/dht11_temp"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function gettemp
# For raspberry pi with DHT11 temperature sensor

function gettemp() {
    temp=$($getdht11_temp)
#    temp=$(/home/$user/bin/dht11_temp)
    loopcnt=0

    while [ -z "$temp" ] && [ $loopcnt -le 8 ]; do
        sleep .5
        temp=$($getdht11_temp)
#        temp=$(/home/$user/bin/dht11_temp)
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


# Check if there are any args on command line
if (( $# != 0 )) ; then
    DEBUG=1
fi

if [ $REMOTE = true ] ; then
    # remote ambient temperature read
    getdht11_temp="ssh pi@10.0.42.37 $HOME/bin/dht11_temp"
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
