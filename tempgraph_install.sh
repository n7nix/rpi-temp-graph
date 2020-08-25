#!/bin/bash

scriptname="`basename $0`"
user="pi"

BINDIR="/home/$user/bin"

REPO_NAME="rpi-temp-graph"
CP="cp"
CHOWN="sudo chown"
SYSTEMCTL="sudo systemctl"

# Refresh scripts only
b_refresh_only=false

# lighttpd config file location
lighttpdcfg_file="/etc/lighttpd/lighttpd.conf"

# List required packages
PKG_REQUIRE="rrdtool librrds-perl libxml-simple-perl lighttpd php-cgi"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
    dbgecho "Checking package: $1"
    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function start_service

function start_service() {
    service="$1"
    echo "Starting: $service"

    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
            exit
        fi
    fi

    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
        systemctl status $service
        exit
    fi
}

# ===== function cfg_lighttpd
# Configure & start lighttpd daemon
# Modifys or creates files:
#   /var/log/lighttpd/error.log
#   /etc/lighttpd/lighttpd.conf
#   /etc/lighttpd/conf-available/15-fastcgi-php
#   /etc/php/$PHPVER/fpm/php.ini

function cfg_lighttpd() {

    echo "start function: ${FUNCNAME[0]}"
    pkg_name="apache2"
    is_pkg_installed $pkg_name
    if [ $? -eq 0 ] ; then
        echo "Remove $pkg_name package"
        sudo apt-get remove -y -q $pkg_name
    fi
    pkg_name="lighttpd"
    is_pkg_installed $pkg_name
    if [ $? -ne 0 ] ; then
        echo "Installing $pkg_name package"
        sudo apt-get install -y -q $pkg_name
    fi

    echo "DEBUG: setup lighttpd log file"
    if [ ! -d "/var/log/lighttpd" ] ; then
        sudo mkdir -p "/var/log/lighttpd"
        sudo touch "/var/log/lighttpd/error.log"
    fi

    $CHOWN -R www-data:www-data "/var/log/lighttpd"

    echo "DEBUG: About to enable lighttpd modules: CHOWN=$CHOWN"
    sudo lighttpd-enable-mod fastcgi
    ls -l /etc/lighttpd/conf-enabled

    # Add these two lines to lighttpd.conf
    # Note: make sure that mod_alias is loaded if you use this:
    grep -i "cgi\.conf" $lighttpdcfg_file > /dev/null
    retcode=$?
    if [ "$retcode" -ne 0 ] ; then

        sudo tee -a $lighttpdcfg_file > /dev/null << EOT
alias.url += ( "/cgi-bin" => server.document-root + "/cgi-bin" )
include "cgi.conf"
EOT
    else
        echo "lighttpd.conf, already has cgi.conf entry."
    fi

    grep -i "deny access to /data directory" $lighttpdcfg_file > /dev/null
    retcode=$?
    echo "DEBUG: grep deny access to: $retcode"
    if [ "$retcode" -ne 0 ] ; then
        # If you're using lighttpd, add the following to your configuration file:
        sudo tee -a $lighttpdcfg_file > /dev/null << EOT
# deny access to /data directory
$HTTP["url"] =~ "^/data/" {
     url.access-deny = ("")
}
EOT
    else
        echo "lighttpd.conf, already has a deny access to /data directory entry."
    fi

    if [ ! -f /etc/lighttpd/cgi.conf ] ; then
    sudo tee -a /etc/lighttpd/cgi.conf > /dev/null  << EOT
server.modules += ( "mod_cgi" )

cgi.assign                 = ( ".pl"  => "/usr/bin/perl",
                               ".cgi" => "/usr/bin/perl",
                               ".rb"  => "/usr/bin/ruby",
                               ".erb" => "/usr/bin/eruby",
                               ".py"  => "/usr/bin/python",
                               ".php" => "/usr/bin/php-cgi" )

index-file.names           += ( "index.pl",   "default.pl",
                               "index.rb",   "default.rb",
                               "index.erb",  "default.erb",
                               "index.py",   "default.py",
                               "index.php",  "default.php" )
EOT
    fi

    if [ 1 -eq 0 ] ; then

    echo "DEBUG: modify 15-fastcgi-php.conf"
    sudo lighttpd-enable-mod fastcgi-php

    # back this file up until verified
    lighttpd_conf_avail_dir="/etc/lighttpd/conf-available"
    sudo cp $lighttpd_conf_avail_dir/15-fastcgi-php.conf $lighttpd_conf_avail_dir/15-fastcgi-php.bak1.conf
    sudo tee -a $lighttpd_conf_avail_dir/15-fastcgi-php.conf > /dev/null << EOT
# -*- depends: fastcgi -*-
# /usr/share/doc/lighttpd/fastcgi.txt.gz
# http://redmine.lighttpd.net/projects/lighttpd/wiki/Docs:ConfigurationOptions#mod_fastcgi-fastcgi

## Start an FastCGI server for php (needs the php5-cgi package)
fastcgi.server += ( ".php" =>
        ((
                "socket" => "/var/run/php/php${PHPVER}-fpm.sock",
                "broken-scriptfilename" => "enable"
        ))
)
EOT

    # To enable PHP in Lighttpd, must modify /etc/php/$PHPVER/fpm/php.ini
    # and uncomment the line cgi.fix_pathinfo=1:
    php_filename="/etc/php/$PHPVER/fpm/php.ini"
    if [ -e "$php_filename" ] ; then
        sudo sed -i -e '/cgi\.fix_pathinfo=/s/^;//' "$php_filename"
    else
        echo "   ERROR: php config file: $php_filename does not exist"
    fi

    fi # end if 1 = 0

    # Change document root directory
    # server.document-root should be: /var/www
    sed -i -e '/server\.document-root / s/server\.document-root .*/server\.document-root = \"\/var\/www\/"/' /etc/lighttpd/lighttpd.conf

    # Check for any configuration syntax errors
    lighttpd -t -f /etc/lighttpd/lighttpd.conf

    # Restart lighttpd
    echo "lighttpd force-reload"
    start_service lighttpd

    sudo service lighttpd force-reload
}

# ===== function update_graph_scripts
function update_graph_scripts() {

    CGI_BINDIR="/var/www/cgi-bin"
    FILE_LIST="db_rpitempupdate.sh db_rpitempbuilder.sh rpicpu_gettemp.sh rpiamb_gettemp.sh dht11/dht11_temp rpitemp.cgi"
    for file_name in `echo ${FILE_LIST}` ; do

        # Look at filename extension
        exten="${file_name##*.}"
        if [ "$exten" = "cgi" ] ; then
            diff $file_name $CGI_BINDIR/ > /dev/null 2>&1
            retcode="$?"
            destdir=$CGI_BINDIR
            CP="sudo cp"
            # Verify CGI_BINDIR exists
            if [ ! -d "$CGI_BINDIR" ] ; then
                sudo mkdir -p "$CGI_BINDIR"
            fi
        else
            diff $file_name $BINDIR > /dev/null 2>&1
            retcode="$?"
            destdir=$BINDIR
        fi

        # Determine if executable exists to read dht11 sensor
        if [[ -x "$file_name" ]] ; then
            dbgecho "$file_name found executable"
        else
            pushd dht11
            make
            if [ "$?" -eq 0 ] ; then
                echo "$file_name build successful"
            else
            echo "$file_name build FAILED"
            fi
            popd
            $CHOWN -R $user:$user dht11
        fi

        case $retcode in
            0)
                echo "No update required for file: $file_name"
            ;;
            1)
                echo "Updating file: $file_name to destination: $destdir"
                $CP -u $file_name $destdir
            ;;
            2)
                echo "Copy file: $file_name to destination: $destdir"
                $CP $file_name $destdir

                echo "DEBUG: Check directory: copy return: $?"
                ls -al $destdir
            ;;
            *)
                echo "Return code: $retcode, not recognized"
            ;;
        esac
    done
    $CHOWN -R www-data:www-data "/var/www/cgi-bin"
}

# ===== function setup_crontab
function setup_crontab() {
    # Does user have a crontab?
    crontab -u $user -l > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "user: $user does NOT have a crontab, creating"
        crontab -u $user -l ;
       {
           echo "# m h  dom mon dow   command"
           echo "*/5  *   *   *   *  /bin/bash /home/$user/bin/db_rpitempupdate.sh"
       } | crontab -u $user -
    else
        echo "user: $user already has a crontab"
    fi

    echo "$user crontab looks like this:"
    echo
    crontab -l -u $user
    echo
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-r][-d][-h]" >&2
   echo "   -u   Update script files only"
   echo "   -d   Set debug flag"
   echo "   -h   Display this message"
   echo
}

# ===== main

echo
echo "temperature graph install START at $(date)"

# Be sure we're running as root
if [[ $EUID = 0 ]] ; then
   echo "Do NOT run as root."
   exit 1
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -u|--update)
         b_refresh_only=true
         echo "Refresh scripts only"
         ;;
      -d|--debug)
         DEBUG=1
         echo "Set debug flag"
         ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      *)
	echo "Unknown option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done

# check if required packages are installed
dbgecho "Check required packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
    echo

    sudo apt-get install -y -q $PKG_REQUIRE
    if [ "$?" -ne 0 ] ; then
        echo "$scriptname: package install failed. Please try this command manually:"
        echo "apt-get install -y $PKG_REQUIRE"
        exit 1
   fi
fi

SRC_DIR=/home/$user/dev/github/$REPO_NAME
echo "DEBUG only: change directory to: $SRC_DIR"
cd $SRC_DIR
pwd

# For reference: get filename extension
# filename=$(basename "$fullfile")
# extension="${filename##*.}"
# filename="${filename%.*}"

echo
echo "Update graph scripts, don't touch RRD database files"

update_graph_scripts
if $b_refresh_only ; then
    echo
    echo "Updating scripts only"
    exit 0
fi

 echo "DEBUG: Configure lighttpd"
 cfg_lighttpd

echo
echo "Verify database files & directories exist"

if [ -d "/home/$user/var/lib/rpi/rrdtemp" ] && [ -d "/home/$user/var/tmp/rpitemp" ] ; then
    echo "About to over write database files:"

    ls -al /home/$user/var/lib/rpi/rrdtemp
    ls -al /home/$user/var/tmp/rpitemp
    echo
    read -p "Over write graph files? (y or n): " -n 1 -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
        echo "Graph files unchanged ..."
    else
        $BINDIR/db_rpitempbuilder.sh
        $CHOWN -R $user:$user /home/$user/var
        $CHOWN -R www-data:www-data /home/$user/var/tmp/rpitemp
    fi

else
    mkdir -p "/home/$user/var/lib/rpi/rrdtemp"
    mkdir -p "/home/$user/var/tmp/rpitemp"
    $BINDIR/db_rpitempbuilder.sh
    $CHOWN -R $user:$user /home/$user/var
    $CHOWN -R www-data:www-data /home/$user/var/tmp/rpitemp
fi

setup_crontab

echo
echo "temperature graph install FINISHED at $(date)"
