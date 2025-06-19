#!/bin/bash

HOST=`/sbin/ip a s eth0 | /bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
echo "testhoteles($HOST) soft raid status is change, can fail!" | mail -s "softraid alert" user@test.com
