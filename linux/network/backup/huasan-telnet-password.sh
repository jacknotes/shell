#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 10

spawn telnet $ip

expect {
	"Password*" {
		send "EBr8\n"
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
		send "tftp 10.10.13.236 put flash:/startup.cfg ${filename}-${date}.cfg\n"
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
