#!/usr/bin/perl

use RRDs;

my $rrdlog = '/var/www/rrd';
my $graphs = '/var/www/rrd';

updatecpudata();
updatecpugraph('day');
updatecpugraph('week');
updatecpugraph('month');
updatecpugraph('year');

sub updatecpugraph {
        my $period    = $_[0];

        RRDs::graph ("$graphs/cpu-$period.png",
                "--start", "-1$period", "-aPNG", "-i", "-z",
                "--alt-y-grid", "-w 700", "-h 150", "-l 0", "-r",
                "-t cpu usage per $period",
                "-v perecent",
                "DEF:user=$rrdlog/cpu.rrd:user:AVERAGE",
                "DEF:system=$rrdlog/cpu.rrd:system:AVERAGE",
                "DEF:idle=$rrdlog/cpu.rrd:idle:AVERAGE",
                "DEF:io=$rrdlog/cpu.rrd:io:AVERAGE",
                "DEF:irq=$rrdlog/cpu.rrd:irq:AVERAGE",
                "CDEF:total=user,system,idle,io,irq,+,+,+,+",
                "CDEF:userpct=100,user,total,/,*",
                "CDEF:systempct=100,system,total,/,*",
#                "CDEF:idlepct=100,idle,total,/,*",
                "CDEF:iopct=100,io,total,/,*",
                "CDEF:irqpct=100,irq,total,/,*",
                "AREA:userpct#0000FF:user cpu usage\\j",
                "STACK:systempct#FF0000:system cpu usage\\j",
#                "STACK:idlepct#00FF00:idle cpu usage\\j",
                "STACK:iopct#FFFF00:iowait cpu usage\\j",
                "STACK:irqpct#00FFFF:irq cpu usage\\j",
                "GPRINT:userpct:MAX:maximal user cpu\\:%3.2lf%%",
                "GPRINT:userpct:AVERAGE:average user cpu\\:%3.2lf%%",
                "GPRINT:userpct:LAST:current user cpu\\:%3.2lf%%\\j",
                "GPRINT:systempct:MAX:maximal system cpu\\:%3.2lf%%",
                "GPRINT:systempct:AVERAGE:average system cpu\\:%3.2lf%%",
                "GPRINT:systempct:LAST:current system cpu\\:%3.2lf%%\\j",
#                "GPRINT:idlepct:MAX:maximal idle cpu\\:%3.2lf%%",
#                "GPRINT:idlepct:AVERAGE:average idle cpu\\:%3.2lf%%",
#                "GPRINT:idlepct:LAST:current idle cpu\\:%3.2lf%%\\j",
                "GPRINT:iopct:MAX:maximal iowait cpu\\:%3.2lf%%",
                "GPRINT:iopct:AVERAGE:average iowait cpu\\:%3.2lf%%",
                "GPRINT:iopct:LAST:current iowait cpu\\:%3.2lf%%\\j",
                "GPRINT:irqpct:MAX:maximal irq cpu\\:%3.2lf%%",
                "GPRINT:irqpct:AVERAGE:average irq cpu\\:%3.2lf%%",
                "GPRINT:irqpct:LAST:current irq cpu\\:%3.2lf%%\\j");
        $ERROR = RRDs::error;
        print "Error in RRD::graph for cpu: $ERROR\n" if $ERROR;
}

sub updatecpudata {
        if ( ! -e "$rrdlog/cpu.rrd") {
                print "Creating cpu.rrd"
                RRDs::create ("$rrdlog/cpu.rrd", "--step=60",
                        "DS:user:COUNTER:600:0:U",
                        "DS:system:COUNTER:600:0:U",
                        "DS:idle:COUNTER:600:0:U",
                        "DS:io:COUNTER:600:0:U",
                        "DS:irq:COUNTER:600:0:U",
                        "RRA:AVERAGE:0.5:1:576",
                        "RRA:AVERAGE:0.5:6:672",
                        "RRA:AVERAGE:0.5:24:732",
                        "RRA:AVERAGE:0.5:144:1460");
                $ERROR = RRDs::error;
                print "Error in RRD::create for cpu: $ERROR\n" if $ERROR;
        }

        my ($cpu, $user, $nice, $system, $idle, $io, $irq, $softirq);

        open STAT, "/proc/stat";
        while(<STAT>) {
                chomp;
                /^cpu\s/ or next;
                ($cpu, $user, $nice, $system, $idle, $io, $irq, $softirq) = split /\s+/;
                last;
        }
        close STAT;
        $user += $nice;
        $irq  += $softirq;

        RRDs::update ("$rrdlog/cpu.rrd",
                "-t", "user:system:idle:io:irq", 
                "N:$user:$system:$idle:$io:$irq");
        $ERROR = RRDs::error;
        print "Error in RRD::update for cpu: $ERROR\n" if $ERROR;

#        print "N:$user:$system:$idle:$io:$irq\n";
}

