# other method

```bash
$ yum install -y mailx
$ vim /etc/mail.rc 
set from=name@test.com
set smtp=smtp.qiye.163.com
set smtp-auth=login
set smtp-auth-user=name@test.com
set smtp-auth-password=password
set ssl-verify=ignore


$ cat /shell/send_mail.sh
#!/bin/bash
HOST=`/sbin/ip a s eth0 | /bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
echo "testhoteles($HOST) soft raid status is change, can fail!" | mail -s "softraid alert" name@test.com


$ vim /etc/rc.d/rc.local
# monitor mdadm
mdadm --monitor --daemonise --delay=60 --scan --program=/shell/send_mail.sh
```
