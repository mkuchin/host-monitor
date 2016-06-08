#!/bin/bash
echo Running infinite monitoring loop
while true
do
	cpu.pl
 	mem.pl
        traf.pl
	sleep 60
        date
done
