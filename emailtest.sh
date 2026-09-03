#!/bin/bash

# Runs from a crontab to periodically send out a 'proof of life' email
#

scriptname="`basename $0`"
DEBUG=

#MSGFILE="emailtemp.txt"

# ==== Main

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

subject="Test email from $(uname -n)"
target="basil@pacabunga.com"

{
    echo "$(date): CPU: $(vcgencmd measure_temp)"
    my_ip=$(ip a show | grep -i "inet " | grep -i "wlan0" | sed 's/^[[:space:]]*//' | cut -d ' ' -f2 | cut -d '/' -f1)
    external_ip=$(curl -s https://ifconfig.me)
    echo "Internal IP address: $my_ip"
    echo "External IP address: $external_ip"
} > $MSGFILE

# Debug mode only displays generated MSG file
if [ ! -z "$DEBUG" ] ; then
    cat "$MSGFILE"
else
    mutt  -s "$subject" "$target" < "$MSGFILE"
    echo "mutt return: $?"
fi
