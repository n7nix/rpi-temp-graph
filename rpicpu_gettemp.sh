#/bin/bash

DEBUG=
REMOTE=false

# local cpu temperature read
getcpu_temp="vcgencmd measure_temp"


# Check if there are any args on command line
if (( $# != 0 )) ; then
    DEBUG=1
fi

if [ $REMOTE = true ] ; then
    # remote cpu temperature read
    getcpu_temp="ssh pi@10.0.42.37 'vcgencmd measure_temp'"
fi


temp=$($getcpu_temp | cut -f2 -d'=' | cut -f1 -d"'")
temp_int=$(echo $temp | cut -f1 -d'.')
temp_dec=$(echo $temp | cut -f2 -d'.')

if [ ! -z "$temp" ] ; then

    echo "Compute Fahrenheit: $temp_int C"
    if ((temp_dec >= 5)) ; then
        ((temp_int++))
        echo "Bump temp_int"
    fi
    temp_fah=$(( ((9 * temp_int)+160)/5 ))
    temp_fah1=$(( ((9 * temp_int)/5)+32 ))

else
    echo "Error temp: $temp"
fi

if [ ! -z "$DEBUG" ] ; then
    echo "Temp raw: $temp, int: $temp_int, dec: $temp_dec, fah: $temp_fah, fah1: $temp_fah1"
else
    echo "$temp_fah"
fi
