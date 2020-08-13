#!/bin/bash

scriptname="`basename $0`"
user="pi"

# Refresh scripts only
b_refresh_only=false

# lighttpd config file location
lighttpdcfg_file="/etc/lighttpd/lighttpd.conf"

# List required packages
PKG_REQUIRE="rrdtool librrds-perl libxml-simple-perl lighttpd"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
    dbgecho "Checking package: $1"
    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function cfg_lighttpd

function cfg_lighttpd() {

    pkg_name="apache2"
    is_pkg_installed $pkg_name
    if [ $? -eq 0 ] ; then
        echo "Remove $pkg_name package"
        apt-get remove -y -q $pkg_name
    fi
    pkg_name="lighttpd"
    is_pkg_installed $pkg_name
    if [ $? -ne 0 ] ; then
        echo "Installing $pkg_name package"
        apt-get install -y -q $pkg_name
    fi

    if [ ! -d "/var/log/lighttpd" ] ; then
        mkdir -p "/var/log/lighttpd"
        touch "/var/log/lighttpd/error.log"
    fi

    chown -R www-data:www-data "/var/log/lighttpd"

    lighttpd-enable-mod fastcgi
    lighttpd-enable-mod fastcgi-php
    ls -l /etc/lighttpd/conf-enabled

    # If you're using lighttpd, add the following to your configuration file:
    cat << 'EOT' >> $lighttpdcfg_file
# deny access to /data directory
$HTTP["url"] =~ "^/data/" {
     url.access-deny = ("")
}
EOT
    # back this file up until verified
    lighttpd_conf_avail_dir="/etc/lighttpd/conf-available"
    cp $lighttpd_conf_avail_dir/15-fastcgi-php.conf $lighttpd_conf_avail_dir/15-fastcgi-php.bak1.conf
    cat << EOT > $lighttpd_conf_avail_dir/15-fastcgi-php.conf
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
        sed -i -e '/cgi\.fix_pathinfo=/s/^;//' "$php_filename"
    else
        echo "   ERROR: php config file: $php_filename does not exist"
    fi

    # Change document root directory
    # server.document-root should be: /var/www
#    sed -i -e '/server\.document-root / s/server\.document-root .*/server\.document-root = \"\/var\/www\/"/' /etc/lighttpd/lighttpd.conf

    # Check for any configuration syntax errors
    lighttpd -t -f /etc/lighttpd/lighttpd.conf

    # Restart lighttpd
    echo "lighttpd force-reload"
    service lighttpd force-reload
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-r][-d][-h]" >&2
   echo "   -r   Refresh files only"
   echo "   -d   Set debug flag"
   echo "   -h   Display this message"
   echo
}

# ===== main

echo
echo "temperature graph install START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -r|--refresh)
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

    apt-get install -y -q $PKG_REQUIRE
    if [ "$?" -ne 0 ] ; then
        echo "$scriptname: package install failed. Please try this command manually:"
        echo "apt-get install -y $PKG_REQUIRE"
        exit 1
   fi
fi

if ! $b_refresh_only ; then
    echo
    echo "Configure lighttpd"
    #cfg_lighttpd
fi

# For reference: get filename extension
#filename=$(basename "$fullfile")
# extension="${filename##*.}"
# filename="${filename%.*}"

echo
echo "Update rrd scripts"

BINDIR="/home/$user/bin"
CGI_BINDIR="/var/www/cgi-bin"
FILE_LIST="db_rpitempupdate.sh rpicpu_gettemp.sh rpiamb_gettemp.sh dht11/dht11_temp rpitemp.cgi"
for file_name in `echo ${FILE_LIST}` ; do
    # Look at filename extension
    exten="${file_name##*.}"
    if [ "$exten" = "cgi" ] ; then
        diff $file_name $CGI_BINDIR/ > /dev/null 2>&1
        retcode="$?"
        destdir=$CGI_BINDIR
    else
        diff $file_name $BINDIR > /dev/null 2>&1
        retcode="$?"
        destdir=$BINDIR
    fi

    case $retcode in
        0)
            echo "No update required for file: $file_name"
            ;;
        1)
            echo "updating file: $file_name to destination: $destdir"
            cp -u $file_name $destdir
            ;;
        2)
            echo "File: $file_name does not exist"
            ;;
        *)
            echo "Return code: $retcode, not recognized"
            ;;
    esac
done


#cp db_rpitempupdate.sh /home/$user/bin
#cp rpicpu_gettemp.sh /home/$user/bin
#cp rpiamb_gettemp.sh /home/$user/bin
#cp dht11/dht11_temp /home/$user/bin
#cp rpitemp.cgi /var/www/cgi-bin