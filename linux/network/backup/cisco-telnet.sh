#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 10


spawn telnet $ip
expect {
	"Username*" {
		send "user\n"
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
	"*SW*>" {
		send "enable\n"
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
	"Password*" {
		send "abc\n"
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
	"*SW*#" {
		send "copy running-config tftp:\n"
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
	"*Address or name of remote host*" {
		send "10.10.13.236\n"
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
	"*Destination filename*" {
		send "${filename}-${date}.cfg\n"
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
	"*SW*#" {
		send "exit\n"
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
