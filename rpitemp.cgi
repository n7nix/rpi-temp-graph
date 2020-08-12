#!/usr/bin/perl -w

# Raspberry Pi temps

use RRDs;
use POSIX qw(strftime);

my $VERSION = "0.1";

############################################################
############## EDIT THESE VALUES BELOW #####################
############################################################

my $xpoints = 650;			 # Graphs width
my $ypoints = 250;			 # Graphs height
my $db_dir = '/home/pi/var/lib/rpi/rrdtemp'; 	 # DB files directory
my $tmp_dir = '/home/pi/var/tmp/rpitemp';	 # Images directory
my $scriptname = 'rpitemp.cgi';	         # Script name

############################################################
### YOU SHOULD NOT HAVE TO EDIT ANYTHING BELOW THIS LINE ###
############################################################

my $date = strftime "%a %b %e %Y %I.%M%p", localtime;
my $points_per_sample = 3;
my $ypoints_err = 96;

my $db_cpu = "$db_dir/rpicpu.rrd";
my $db_ambient = "$db_dir/rpiamb.rrd";


## The degree symbol  Pango-WARNING **: Invalid UTF-8 string passed to pango_layout_set_text()
#$temp_units = '�F';
## This doesn't work at all
# $temp_units = '&deg;F';
$temp_units = 'F';

my @graphs = (
	      { title => 'Daily Graphs',   seconds => 3600*24,        },
	      { title => 'Weekly Graphs',  seconds => 3600*24*7,      },
	      { title => 'Monthly Graphs', seconds => 3600*24*31,     },
	      { title => 'Yearly Graphs',  seconds => 3600*24*365, },
	     );

sub graph_temperature($$$)
{
	my $range = shift;
	my $file = shift;
	my $title = shift;
	my $step = $range*$points_per_sample/$xpoints;

	my ($graphret,$xs,$ys) = RRDs::graph($file,
		'--imgformat', 'PNG',
		'--width', $xpoints,
		'--height', $ypoints,
		'--start', "-$range",
		"--title=  Raspberry Pi Temperatures",
		'--vertical-label', "Degrees $temp_units",
		'--units-exponent', 0,
		'--lazy',
		'-Y',

		"DEF:cpu_c=$db_cpu:cpu:AVERAGE",
		"DEF:ambient_c=$db_ambient:ambient:AVERAGE",
		"COMMENT:                  Min         Max        Avg        Last\\n",
		'LINE2:cpu_c#2E993D:CPU Core   ',
  	        "GPRINT:cpu_c:MIN: %5.2lf $temp_units",
		"GPRINT:cpu_c:MAX: %5.2lf $temp_units",
		"GPRINT:cpu_c:AVERAGE: %5.2lf $temp_units",
		"GPRINT:cpu_c:LAST: %5.2lf $temp_units\\n",
		'LINE2:ambient_c#DD3F4A:Ambient    ',
  	        "GPRINT:ambient_c:MIN: %6.2lf $temp_units",
		"GPRINT:ambient_c:MAX: %6.2lf $temp_units",
		"GPRINT:ambient_c:AVERAGE: %6.2lf $temp_units",
		"GPRINT:ambient_c:LAST: %6.2lf $temp_units\\n",
		"COMMENT: \\n",
		"COMMENT:Generated by Raspberry Pi Temp $VERSION - $date",
	);

	my $ERR=RRDs::error;
	die "ERROR: $ERR\n" if $ERR;
}


sub print_html()
{
	print "Content-Type: text/html\n\n";

	print <<HEADER;
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html>
<head>
<title>Raspberry Pi Temperatures</title>
<meta http-equiv="pragma" content="no-cache"/>
<meta http-equiv="refresh" content="600"/>
<meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
<style type="text/css">

body
{
	background-color: #6e73b5;
#	background-color: #ABABAB;
#	background-color: #333399;
#color: #737367;
#color: #ffff00;
color: #000000;
	font-size: 11px;
	margin: 0px;
	padding: 0px;
	text-align: center;
	font-family: arial, helvetica, sans-serif;
}

a
{
	text-decoration: none;
	color: #464646;
	background-color: #6e73b5;
#	background-color: #ABABAB;
}

a:visited
{
	color: #59594F;
	background-color: #6e73b5;
#	background-color: #ABABAB;
}

a:hover
{
	color: #FF6633;
	background-color: #6e73b5;
#	background-color: #ABABAB;
}

a:active
{
	color: #444444;
	background-color: #6e73b5;
#	background-color: #ABABAB;
}

.graphtitle
{
	background-color: #dddddd;
	color: #222222;
	width: 780px;
	margin: 0 auto;
}

.page_header
{
	margin-top: 0px;
	padding-top: 25px;
}

.page_footer
{
	margin-bottom: 10px;
	padding-top: 0px;
}

</style>
</head>
<body>
HEADER
	print "<h1>Raspberry Pi Temperatures</h1>\n";
	print "<h3>Reading CPU Core & dht11 sensors</h3>\n";

	display_current();

	for my $n (0..$#graphs) {
		print "<div class=\"graphtitle\"><h2>".$graphs[$n]{title}."</h2></div>\n";
		print "<p><img src=\"$scriptname?${n}-temperature\" alt=\"RRDWeather\"/></p>\n";
	}


	print <<FOOTER;
<table border="0" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center">
 <a href="http://www.nwdigitalradio.com/" onclick="window.open(this.href); return false;">Basil Gunn</a>
<a> $VERSION by</a>
<a href="http://www.nwdigitalradio.com" onclick="window.open(this.href); return false;">Basil N7NIX</a></td></tr>
</table>
FOOTER
}

sub print_val($)
{
	my $val = shift;
	$hash = RRDs::info "$val";
	foreach my $key (keys %$hash){
		if($key =~ /last_ds/){
			print " 			<td>$$hash{$key}</td>";
		}
	}
}
sub print_row($$){
	my $title = shift;
	my $val = shift;

	print "				<tr>\n";
	print "					<td>$title</td>\n";
	print_val("$val");
	print "				</tr>\n";
	print " 			<tr>\n";
}

sub display_current()
{

	my $cur_time = time();           # set current time
	my $end_time = $cur_time;        # set end time to now
	my $start_time = $end_time - 10; # set start to now minus 10

	print " 	<table style=\"background-color: rgb(214, 255, 209);font-family: Arial;color: #000000;text-align: right; margin-left: auto; margin-right: auto; width: 20%;\" border=\"2\"\n";
#	print "table style=\"background-color: rgb(214, 255, 209); width: 742px; height: 71px; text-align: right; margin-left: auto; margin-right: auto;\"\n";
	print " 		cellpadding=\"2\" cellspacing=\"2\">\n";
	print " 		<tbody>\n";

	print_row("CPU Core temp", "$db_cpu");
	print_row("Ambient temp","$db_ambient");

	print " 			</tbody>\n";
	print " 			</table>\n";

#	print "<h1>Greenhouse outside temperature is \n";
#	$hash = RRDs::info "$db_grnhos";
#	foreach my $key (keys %$hash){
#		if($key =~ /last_ds/){
#			printf "%12.1f ", $$hash{$key}, "</h1>";
#		}
#    }


}

sub send_image($)
{
	my $file = shift;
	-r $file or do {
		print "Content-type: text/plain\n\nERROR: can't find $file\n";
		exit 1;
	};

	print "Content-type: image/png\n";
	print "Content-length: ".((stat($file))[7])."\n";
	print "\n";
	open(IMG, $file) or die;
	my $data;
	print $data while read IMG, $data, 1024;
}

sub main()
{
	mkdir $tmp_dir, 0777 unless -d $tmp_dir;

	my $img = $ENV{QUERY_STRING};
	if(defined $img and $img =~ /\S/) {
		if($img =~ /^(\d+)-temperature$/) {
			my $file = "$tmp_dir/RRDWeather_$1_temperature.png";
			graph_temperature($graphs[$1]{seconds}, $file, $graphs[$1]{title});
			send_image($file);
		} else {
			die "ERROR: invalid argument\n";
		}
	}
	else {
		print_html;
	}
}

main;
