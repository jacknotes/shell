#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 30

spawn ssh user@$ip

expect {
	"Password*" {
		send "EBr8123\n"
	}
   	timeout {
   	    puts "Timeout occurred, exiting."
   	    exit 1
   	}
   	eof {
   	    puts "Unexpected end of file, exiting."
   	    exit 1
   	}	
}

expect {
	"<*SW*>" {
		send "tftp 192.168.13.236 put flash:/vrpcfg.zip ${filename}-${date}.zip\n"
	}
   	timeout {
   	    puts "Timeout occurred, exiting."
   	    exit 1
   	}
   	eof {
   	    puts "Unexpected end of file, exiting."
   	    exit 1
   	}	
}

expect {
	"<*SW*>" {
		send "quit\n"
	}
   	timeout {
   	    puts "Timeout occurred, exiting."
   	    exit 1
   	}
   	eof {
   	    puts "Unexpected end of file, exiting."
   	    exit 1
   	}	
}
