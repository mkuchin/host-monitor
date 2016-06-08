# host-monitor

#### Simple host CPU, memory and traffic monitoring
Usage charts generated with [rrdtool](http://oss.oetiker.ch/rrdtool/).

#### How to run:
     docker run -d -v rrd:/var/www/rrd --restart=always --net=host --name=monitor hyper/host-monitor

Web pages with usage charts will be updated every minute inside `rrd` volume

[Working example](http://vpn.devspire.com.au/)
