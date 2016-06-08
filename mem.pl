#!/usr/bin/perl
#
# coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_mem.pl

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/www/rrd';
# define location of images
my $img = '/var/www/rrd';

# get memory usage
my $mem = `free -b -o |grep Mem`;
my $swap = `free -b -o |grep Swap |cut -c19-29 |sed 's/ //g'`;
my @mema = split(/\s+/, $mem);
my $buffers = $mema[5];
my $cached = $mema[6];
$mem = $mema[2] - $buffers - $cached;
#print "$mem + $buffers + $cached\n";
# remove eol chars
#chomp($mem);
chomp($swap);

#printf "memory: %.2f Mbytes, swap: %.2f Mbytes\n", $mem/1024/1024, $swap/1024/1024;

# if rrdtool database doesn't exist, create it
if (! -e "$rrd/mem.rrd")
{
	print "creating rrd database for memory usage...\n";
	system("$rrdtool create $rrd/mem.rrd -s 300"
		." DS:mem:GAUGE:600:0:U"
		." DS:buf:GAUGE:600:0:U"
		." DS:cache:GAUGE:600:0:U"
		." DS:swap:GAUGE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

# insert values into rrd
`$rrdtool update $rrd/mem.rrd -t mem:buf:cache:swap N:$mem:$buffers:$cached:$swap`;

# create graphs
&CreateGraph("day");
&CreateGraph("week");
&CreateGraph("month"); 
&CreateGraph("year");

sub CreateGraph
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

	system("$rrdtool graph $img/mem-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"memory usage over the last $_[0]\""
		." --lazy"
		." -h 150 -w 700"
		." -l 0"
		." -a PNG"
		." -v \"bytes\""
		." -b 1024"
		." DEF:mem=$rrd/mem.rrd:mem:AVERAGE"
		." DEF:buf=$rrd/mem.rrd:buf:AVERAGE"
		." DEF:cache=$rrd/mem.rrd:cache:AVERAGE"
		." DEF:swap=$rrd/mem.rrd:swap:AVERAGE"
		." CDEF:total=mem,swap,buf,cache,+,+,+"
		." CDEF:res=mem,buf,cache,+,+"
		." AREA:mem#FFCC66:\"Physical Memory Usage\""
		." STACK:buf#FF9999:\"Buffers\""
		." STACK:cache#FF0099:\"Cache\""
		." STACK:swap#FF9900:\"Swap Memory Usage\\n\""
		." GPRINT:mem:MAX:\"Residental  Max\\: %5.1lf %s\""
		." GPRINT:mem:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:mem:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:buf:MAX:\"Buffers     Max\\: %5.1lf %s\""
		." GPRINT:buf:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:buf:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:cache:MAX:\"Cache       Max\\: %5.1lf %s\""
		." GPRINT:cache:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:cache:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:swap:MAX:\"Swap        Max\\: %5.1lf %s\""
		." GPRINT:swap:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:swap:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:total:MAX:\"Total       Max\\: %5.1lf %s\""
		." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:total:LAST:\" Current\\: %5.1lf %s\\n\""
		." LINE1:res#CC9966"
		." LINE1:total#CC6600 > /dev/null");
}
