#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 10

spawn ssh user@$ip -p 22

expect {
	"*password*" {
		send "abcabc\n"
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
	"*<FW*" {
		send "tftp 10.10.13.236 put flash:/vrpcfg.zip ${filename}-${date}.zip\n"
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
	"*<FW*" {
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
