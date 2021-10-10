#!/bin/bash
#
# tempgraph_ctrl.sh
#
# Start, Stop & display status for RPi temperature & CPU activity graph functions

DEBUG=

scriptname="`basename $0`"
user="pi"

# function STOP tempgraph

# Only comment out lines that include these scripts:
#  db_rpitempupdate.sh
#  db_rpicpuload_update.sh

function tempgraph_stop () {

    #  take the output of crontab -l, which is obviously your complete
    #  crontab, manipulates it with sed, and then writes a new crontab
    #  based on its output using crontab -.

    crontab -l | sed '/db_rpitempupdate\.sh/s!^!#!' | crontab -
    crontab -l | sed '/db_rpicpuload_update\.sh/s!^!#!' | crontab -

    return;
}

# function START tempgraph

function tempgraph_start () {

    crontab -u $user -l > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "user: $user does NOT have a crontab, creating"
       {
           echo "# m h  dom mon dow   command"
           echo "*/5  *   *   *   *  /bin/bash /home/$user/bin/db_rpitempupdate.sh"
           echo "*    *   *   *   *  /bin/bash /home/$user/bin/db_rpicpuload_update.sh"
       } | crontab -u $user -
    else

        # crontab -l | sed '/# *\([^ ][^ ]*  *\)\{5\}[^ ]*test\.sh/s/^# *//' | crontab -
        crontab -l | sed '/db_rpitempupdate\.sh/s!^#!!' | crontab -
        crontab -l | sed '/db_rpicpuload_update\.sh/s!^#!!' | crontab -
    fi
    return;
}

# function tempgraph status

# Display status of functions required for temperature & CPU activity
# graphing

function tempgraph_status () {

    echo
    echo "=== status start: $(date) ==="
    echo
    echo "=== CPU & Ambient sensor check ==="

    program_name="rpicpu_gettemp.sh"
    # type command will return 0 if program is installed
    type -P "$program_name" &>/dev/null
    if [ $? -ne 0 ] ; then
       echo "Script: $program_name not installed"
    else
       echo "Temp $program_name: $($program_name)"
    fi

    program_name="rpiamb_gettemp.sh"
    # type command will return 0 if program is installed
    type -P "$program_name" &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "Script: $program_name not installed"
    else
        echo "Temp $program_name: $($program_name)"
    fi

    # This gets the 5 minute load average
    CPULOAD=$(cat /proc/loadavg | cut -f2 -d ' ')
    # scale it to fit with temperature graphs
    CPULOAD1=$(echo "($CPULOAD * 100) / 1" | bc )
    echo "CPU load average: $CPULOAD1"

    # Get lighttpd daemon status
    systemctl --no-pager status lighttpd > /dev/null 2>&1
    retcode="$?"
    if [ "$retcode" -eq 0 ] ; then
        lighty_status="OK"
    else
        lighty_status="FAILED: $retcode"
    fi

    echo
    echo "=== lighttpd daemon status $lighty_status ==="

    # if debug flag is set display all of lighttpd status
    if [ ! -z "$DEBUG" ] ; then
        systemctl --no-pager status lighttpd
    fi

    echo
    echo "=== lighttphd enabled modules ==="
    ls -1 /etc/lighttpd/conf-enabled/

    echo
    echo "=== lighttpd document root ==="
    grep -i "document-root" /etc/lighttpd/lighttpd.conf

    echo
    echo "=== Web page check ==="
    curl -I "http://localhost/cgi-bin/rpitemp.cgi" 2>&1 | grep -w "200\|301"
    if [ $? -eq 0 ] ; then
        result="UP"
    else
        result="DOWN"
    fi
    echo "RPi temp webpage is $result"

    echo
    echo "=== rrd file check ==="
    ls -al ~/var/lib/rpi/rrdtemp
    echo
    echo "=== png file check ==="
    ls -al ~/var/tmp/rpitemp

    echo
    echo "=== crontab check ==="
    crontab -l | grep -i "db_rpitempupdate.sh"
    if [ $? -eq 0 ] ; then
        result="OK"
    else
        result="MISSING rpi temperature update"
    fi
    echo "Crontab entery for temperature is $result"
    crontab -l | grep -i "db_rpicpuload_update.sh"
    if [ $? -eq 0 ] ; then
        result="OK"
    else
        result="MISSING rpi CPU load average update"
    fi
    echo "Crontab entery for CPU load is $result"
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-d][-h][status][stop][start]"
        echo "                  No args will show status of temperature graph"
        echo "  -d              Set DEBUG flag"
	echo
        echo "                  args with dashes must come before other arguments"
	echo
        echo "  start           start RPi temperature data collection & graph"
        echo "  stop            stop RPi Temperature data collection & graph"
        echo "  status          display status of RPi Temperature graphing functions"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}


# ===== main


while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    stop)
        tempgraph_stop
	exit 0
    ;;
    start)
        tempgraph_start
	exit 0
    ;;
    status)
        tempgraph_status
        exit 0
    ;;
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
   ;;
    -h|--help|-?)
        usage
        exit 0
   ;;
   *)
        echo "Unrecognized command line argument: $APP_ARG"
        usage
        exit 0
   ;;

esac

shift # past argument
done

tempgraph_status
