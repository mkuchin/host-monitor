#!/usr/bin/perl
#
# copyright Martin Pot 2003
# http://martybugs.net/linux/rrdtool/traffic.cgi
#
# rrd_traffic.pl

use RRDs;

# define location of rrdtool databases
my $rrd = '/var/www/rrd';
# define location of images
my $img = '/var/www/rrd';

# process data for each interface (add/delete as required)
&ProcessInterface("eth0", "internet");
#&ProcessInterface("eth1", "internet gateway");
#&ProcessInterface("eth2", "MartinMast wireless link");
#&ProcessInterface("eth3", "home wireless");

sub ProcessInterface
{
# process interface
# inputs: $_[0]: interface name (ie, eth0/eth1/eth2/ppp0)
#	  $_[1]: interface description 

	# get network interface info
	my $in = `/sbin/ifconfig $_[0] |grep bytes|cut -d":" -f2|cut -d" " -f1`;
	my $out = `/sbin/ifconfig $_[0] |grep bytes|cut -d":" -f3|cut -d" " -f1`;

	# remove eol chars
	chomp($in);
	chomp($out);

#	print "$_[0] traffic in, out: $in, $out\n";

	# if rrdtool database doesn't exist, create it
	if (! -e "$rrd/$_[0].rrd")
	{
		print "creating rrd database for $_[0] interface...\n";
		RRDs::create "$rrd/$_[0].rrd",
			"-s 300",
			"DS:in:DERIVE:120:0:125000000",
			"DS:out:DERIVE:120:0:125000000",
			"RRA:AVERAGE:0.5:1:2880",
			"RRA:AVERAGE:0.5:6:672",
			"RRA:AVERAGE:0.5:24:732",
			"RRA:AVERAGE:0.5:144:1460";
	}

	# insert values into rrd
	RRDs::update "$rrd/$_[0].rrd",
		"-t", "in:out",
		"N:$in:$out";

	# create traffic graphs
	&CreateGraph($_[0], "day", $_[1]);
	&CreateGraph($_[0], "week", $_[1]);
	&CreateGraph($_[0], "month", $_[1]); 
	&CreateGraph($_[0], "year", $_[1]);
}

sub CreateGraph
{
# creates graph
# inputs: $_[0]: interface name (ie, eth0/eth1/eth2/ppp0)
#	  $_[1]: interval (ie, day, week, month, year)
#	  $_[2]: interface description 

	RRDs::graph "$img/$_[0]-$_[1].png",
		"-s -1$_[1]",
		"-t traffic on $_[0] :: $_[2]",
		"--lazy",
		"-h", "150", "-w", "700",
		"-l 0",
		"-a", "PNG",
		"-v bytes/sec",
		"DEF:in=$rrd/$_[0].rrd:in:AVERAGE",
		"DEF:out=$rrd/$_[0].rrd:out:AVERAGE",
		"CDEF:in_neg=in,-1,*",
		"AREA:in_neg#32CD32:Incoming",
		"LINE1:in_neg#336600",
		"GPRINT:in:MAX:  Max\\: %5.1lf %s",
		"GPRINT:in:AVERAGE: Avg\\: %5.1lf %S",
		"GPRINT:in:LAST: Current\\: %5.1lf %Sbytes/sec\\n",
		"AREA:out#4169E1:Outgoing",
		"LINE1:out#0033CC",
		"GPRINT:out:MAX:  Max\\: %5.1lf %S",
		"GPRINT:out:AVERAGE: Avg\\: %5.1lf %S",
		"GPRINT:out:LAST: Current\\: %5.1lf %Sbytes/sec",
		"HRULE:0#000000";
	if ($ERROR = RRDs::error) { print "$0: unable to generate $_[0] $_[1] traffic graph: $ERROR\n"; }
}

