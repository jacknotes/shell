# 脚本作用
使用openssl客户端测试服务器使用的TLS版本。



# 目录结构
```bash
[root@hw-blog test-ssl-version]# tree .
.
├── openssl_client_test.sh
└── source
    └── markli.cn.conf
```



# 配置nginx配置文件
更改脚本`openssl_client_test.sh`里面的变量`DOMAIN_NAME`，将值更改为你需要测试的域名，例如`markli.cn`，因为变量`NGINX_CONFIG_FILE`会引用`DOMAIN_NAME`变量的值，因此请在source目录下存放名为`markli.cn.conf`的配置文件
```bash
DOMAIN_NAME='markli.cn'
NGINX_CONFIG_FILE="./source/${DOMAIN_NAME}.conf"
```



# 脚本使用



## 脚本帮助
* 需要先执行start命令，生成配置文件。
* 才可执行check、filter命令。
```bash
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh -h
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh 
[WARN] To execute the 'check'、'filter' command, the 'start' command must be executed first
Usage: ./openssl_client_test.sh [ start | filter ARG1 | check ]
ARG1 = [ SERVER_NAME | all ]	example: ./openssl_client_test.sh filter www.test.com
```



## 脚本执行
```bash
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh start 
.........
.........
139888105150272:error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:ssl/record/rec_layer_s3.c:1563:SSL alert number 70
CONNECTED(00000003)
---
no peer certificate available
---
No client certificate CA names sent
---
SSL handshake has read 7 bytes and written 132 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1
    Cipher    : 0000
    Session-ID: 
    Session-ID-ctx: 
    Master-Key: 
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1740636851
    Timeout   : 7200 (sec)
    Verify return code: 0 (ok)
    Extended master secret: no
---
139835184469824:error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:ssl/record/rec_layer_s3.c:1563:SSL alert number 70
CONNECTED(00000003)
---
no peer certificate available
---
No client certificate CA names sent
---
SSL handshake has read 7 bytes and written 132 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.1
    Cipher    : 0000
    Session-ID: 
    Session-ID-ctx: 
    Master-Key: 
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1740636851
    Timeout   : 7200 (sec)
    Verify return code: 0 (ok)
    Extended master secret: no
---
depth=1 C = US, O = Let's Encrypt, CN = R10
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN = *.markli.cn
verify return:1
CONNECTED(00000003)
---
Certificate chain
 0 s:CN = *.markli.cn
   i:C = US, O = Let's Encrypt, CN = R10
 1 s:C = US, O = Let's Encrypt, CN = R10
   i:C = US, O = Internet Security Research Group, CN = ISRG Root X1
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIE6DCCA9CgAwIBAgISBEvXv1OjudWTDl2y9SvAFuarMA0GCSqGSIb3DQEBCwUA
MDMxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQwwCgYDVQQD
EwNSMTAwHhcNMjUwMTI1MTYwMzU0WhcNMjUwNDI1MTYwMzUzWjAWMRQwEgYDVQQD
DAsqLm1hcmtsaS5jbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPcB
8TnQ1YCn2agCFrbzQlnTAZtphjPv3u3YHgTFm8hqYqQjXqjA9n0Xeq6LP/hMPK90
FN86Zf5LORy5mH1JKbip7AU0PHHQKZ9Hm4KGcrxYHOEcY8SniuUx6LYZfd8O2gG6
FwloUlnzFr3LCcI3GAGVClnxPCrjiVl0pRDQnb/vAseehKPvXZBykrQBx2AOIsE7
86b5GCcU6naq1ss73x7GYi/yKdYEP6HI5PwyjC2uXRpxJyngQmU5+PJ9vT+9GZj1
h7h+qwt1S0D5bQuvOThvoZNZRn3RhNeIBjpK1gO9H+LPyLmJ3IEViLz32Da9u6qB
wxjDJkmK0VLyaY268/8CAwEAAaOCAhEwggINMA4GA1UdDwEB/wQEAwIFoDAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4E
FgQUEB09E0i6UQ8WPPKJJMRxdH+cezQwHwYDVR0jBBgwFoAUu7zDR6XkvKnGw6Ry
DBCNojXhyOgwVwYIKwYBBQUHAQEESzBJMCIGCCsGAQUFBzABhhZodHRwOi8vcjEw
Lm8ubGVuY3Iub3JnMCMGCCsGAQUFBzAChhdodHRwOi8vcjEwLmkubGVuY3Iub3Jn
LzAWBgNVHREEDzANggsqLm1hcmtsaS5jbjATBgNVHSAEDDAKMAgGBmeBDAECATCC
AQYGCisGAQQB1nkCBAIEgfcEgfQA8gB3AKLjCuRF772tm3447Udnd1PXgluElNcr
XhssxLlQpEfnAAABlJ5qKHEAAAQDAEgwRgIhAI7RwjjeRNilGLtFnW03Azc73pi4
P4bqjb/8w/H/0ybiAiEA85xtEtByPzbfb0wLJ2Cbs/V544svLRvfATKwDFRXHiMA
dwDgkrP8DB3I52g2H95huZZNClJ4GYpy1nLEsE2lbW9UBAAAAZSeaijBAAAEAwBI
MEYCIQCIIAOo0L6zQuodZ5XW45HVZ28/MkpOWJ6uPPha1HiYzwIhAJyihoZXktn5
JoPsr3Aojni7MFnOp/t3PS26n298fyTcMA0GCSqGSIb3DQEBCwUAA4IBAQALOh2a
jVRzF0kTaSN3IZqcTi1WLgYN87p/Yu8nN3gJlCV5iVMwXQziS/gG3OMKFkqeZOzF
Xh6/b4lOSvGsVbnm5AKiIKvHKK0DlzN/8To7LNMY21ONcJHFpZb27Yc6A5SW2eJw
51NNqjva5sJZKh5X58EdLPh+2z6Nkk80+c/9jDqcqep02DY9/TqopOFzmJPAfKLQ
yGLJ2HIL1u/3PWYI3PptuZyYcVunN2xWPZQF1OWtNroTnWGY9Mwrf7pAbcNulfVN
owB3ksgCFQJJwV4N266Z9toGKL6IJ96CBRdtG46O1tLX1WWs/PlNsxtuPjd3M1yZ
JNabk/KYGVkH7RfZ
-----END CERTIFICATE-----
subject=CN = *.markli.cn

issuer=C = US, O = Let's Encrypt, CN = R10

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3034 bytes and written 315 bytes
Verification error: unable to get local issuer certificate
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES256-GCM-SHA384
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES256-GCM-SHA384
    Session-ID: 011595C93982A527D177E21C1CAB443EA29C13A055A9BAE83CF1CFF9629DCA83
    Session-ID-ctx: 
    Master-Key: CB437E2965C22FA6A1F152E3C5B8EDE2B0403BAD224CE437BED72CE8F4B77A9DBA7545FAB69922084092B4C1FC7AD626
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1740636851
    Timeout   : 7200 (sec)
    Verify return code: 20 (unable to get local issuer certificate)
    Extended master secret: yes
---
depth=1 C = US, O = Let's Encrypt, CN = R10
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN = *.markli.cn
verify return:1
CONNECTED(00000003)
---
Certificate chain
 0 s:CN = *.markli.cn
   i:C = US, O = Let's Encrypt, CN = R10
 1 s:C = US, O = Let's Encrypt, CN = R10
   i:C = US, O = Internet Security Research Group, CN = ISRG Root X1
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIE6DCCA9CgAwIBAgISBEvXv1OjudWTDl2y9SvAFuarMA0GCSqGSIb3DQEBCwUA
MDMxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQwwCgYDVQQD
EwNSMTAwHhcNMjUwMTI1MTYwMzU0WhcNMjUwNDI1MTYwMzUzWjAWMRQwEgYDVQQD
DAsqLm1hcmtsaS5jbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPcB
8TnQ1YCn2agCFrbzQlnTAZtphjPv3u3YHgTFm8hqYqQjXqjA9n0Xeq6LP/hMPK90
FN86Zf5LORy5mH1JKbip7AU0PHHQKZ9Hm4KGcrxYHOEcY8SniuUx6LYZfd8O2gG6
FwloUlnzFr3LCcI3GAGVClnxPCrjiVl0pRDQnb/vAseehKPvXZBykrQBx2AOIsE7
86b5GCcU6naq1ss73x7GYi/yKdYEP6HI5PwyjC2uXRpxJyngQmU5+PJ9vT+9GZj1
h7h+qwt1S0D5bQuvOThvoZNZRn3RhNeIBjpK1gO9H+LPyLmJ3IEViLz32Da9u6qB
wxjDJkmK0VLyaY268/8CAwEAAaOCAhEwggINMA4GA1UdDwEB/wQEAwIFoDAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4E
FgQUEB09E0i6UQ8WPPKJJMRxdH+cezQwHwYDVR0jBBgwFoAUu7zDR6XkvKnGw6Ry
DBCNojXhyOgwVwYIKwYBBQUHAQEESzBJMCIGCCsGAQUFBzABhhZodHRwOi8vcjEw
Lm8ubGVuY3Iub3JnMCMGCCsGAQUFBzAChhdodHRwOi8vcjEwLmkubGVuY3Iub3Jn
LzAWBgNVHREEDzANggsqLm1hcmtsaS5jbjATBgNVHSAEDDAKMAgGBmeBDAECATCC
AQYGCisGAQQB1nkCBAIEgfcEgfQA8gB3AKLjCuRF772tm3447Udnd1PXgluElNcr
XhssxLlQpEfnAAABlJ5qKHEAAAQDAEgwRgIhAI7RwjjeRNilGLtFnW03Azc73pi4
P4bqjb/8w/H/0ybiAiEA85xtEtByPzbfb0wLJ2Cbs/V544svLRvfATKwDFRXHiMA
dwDgkrP8DB3I52g2H95huZZNClJ4GYpy1nLEsE2lbW9UBAAAAZSeaijBAAAEAwBI
MEYCIQCIIAOo0L6zQuodZ5XW45HVZ28/MkpOWJ6uPPha1HiYzwIhAJyihoZXktn5
JoPsr3Aojni7MFnOp/t3PS26n298fyTcMA0GCSqGSIb3DQEBCwUAA4IBAQALOh2a
jVRzF0kTaSN3IZqcTi1WLgYN87p/Yu8nN3gJlCV5iVMwXQziS/gG3OMKFkqeZOzF
Xh6/b4lOSvGsVbnm5AKiIKvHKK0DlzN/8To7LNMY21ONcJHFpZb27Yc6A5SW2eJw
51NNqjva5sJZKh5X58EdLPh+2z6Nkk80+c/9jDqcqep02DY9/TqopOFzmJPAfKLQ
yGLJ2HIL1u/3PWYI3PptuZyYcVunN2xWPZQF1OWtNroTnWGY9Mwrf7pAbcNulfVN
owB3ksgCFQJJwV4N266Z9toGKL6IJ96CBRdtG46O1tLX1WWs/PlNsxtuPjd3M1yZ
JNabk/KYGVkH7RfZ
-----END CERTIFICATE-----
subject=CN = *.markli.cn

issuer=C = US, O = Let's Encrypt, CN = R10

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3114 bytes and written 323 bytes
Verification error: unable to get local issuer certificate
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 20 (unable to get local issuer certificate)
---
./output/ssl_tls1_1_blog.markli.cn.txt nook
./output/ssl_tls1_1_docker.markli.cn.txt nook
./output/ssl_tls1_1_memos.markli.cn.txt nook
./output/ssl_tls1_1_monitor.markli.cn.txt nook
./output/ssl_tls1_1_opms.markli.cn.txt nook
./output/ssl_tls1_1_ql.markli.cn.txt nook
./output/ssl_tls1_1_rd.markli.cn.txt nook
./output/ssl_tls1_1_syncthing.markli.cn.txt nook
./output/ssl_tls1_2_blog.markli.cn.txt ok
./output/ssl_tls1_2_docker.markli.cn.txt ok
./output/ssl_tls1_2_memos.markli.cn.txt ok
./output/ssl_tls1_2_monitor.markli.cn.txt ok
./output/ssl_tls1_2_opms.markli.cn.txt ok
./output/ssl_tls1_2_ql.markli.cn.txt ok
./output/ssl_tls1_2_rd.markli.cn.txt ok
./output/ssl_tls1_2_syncthing.markli.cn.txt ok
./output/ssl_tls1_3_blog.markli.cn.txt ok
./output/ssl_tls1_3_docker.markli.cn.txt ok
./output/ssl_tls1_3_memos.markli.cn.txt ok
./output/ssl_tls1_3_monitor.markli.cn.txt ok
./output/ssl_tls1_3_opms.markli.cn.txt ok
./output/ssl_tls1_3_ql.markli.cn.txt ok
./output/ssl_tls1_3_rd.markli.cn.txt ok
./output/ssl_tls1_3_syncthing.markli.cn.txt ok
./output/ssl_tls1_blog.markli.cn.txt nook
./output/ssl_tls1_docker.markli.cn.txt nook
./output/ssl_tls1_memos.markli.cn.txt nook
./output/ssl_tls1_monitor.markli.cn.txt nook
./output/ssl_tls1_opms.markli.cn.txt nook
./output/ssl_tls1_ql.markli.cn.txt nook
./output/ssl_tls1_rd.markli.cn.txt nook
./output/ssl_tls1_syncthing.markli.cn.txt nook
```
> 如上最后输出的就是哪个域名支持哪个TLS协议是否ok，如果支持则为ok，不支持则为nook


执行完成后目录结构
```bash
[root@hw-blog test-ssl-version]# tree .
.
├── openssl_client_test.sh
├── output
│   ├── false.txt
│   ├── markli.cn.servername.txt
│   ├── ssl_tls1_1_blog.markli.cn.txt
│   ├── ssl_tls1_1_docker.markli.cn.txt
│   ├── ssl_tls1_1_memos.markli.cn.txt
│   ├── ssl_tls1_1_monitor.markli.cn.txt
│   ├── ssl_tls1_1_opms.markli.cn.txt
│   ├── ssl_tls1_1_ql.markli.cn.txt
│   ├── ssl_tls1_1_rd.markli.cn.txt
│   ├── ssl_tls1_1_syncthing.markli.cn.txt
│   ├── ssl_tls1_2_blog.markli.cn.txt
│   ├── ssl_tls1_2_docker.markli.cn.txt
│   ├── ssl_tls1_2_memos.markli.cn.txt
│   ├── ssl_tls1_2_monitor.markli.cn.txt
│   ├── ssl_tls1_2_opms.markli.cn.txt
│   ├── ssl_tls1_2_ql.markli.cn.txt
│   ├── ssl_tls1_2_rd.markli.cn.txt
│   ├── ssl_tls1_2_syncthing.markli.cn.txt
│   ├── ssl_tls1_3_blog.markli.cn.txt
│   ├── ssl_tls1_3_docker.markli.cn.txt
│   ├── ssl_tls1_3_memos.markli.cn.txt
│   ├── ssl_tls1_3_monitor.markli.cn.txt
│   ├── ssl_tls1_3_opms.markli.cn.txt
│   ├── ssl_tls1_3_ql.markli.cn.txt
│   ├── ssl_tls1_3_rd.markli.cn.txt
│   ├── ssl_tls1_3_syncthing.markli.cn.txt
│   ├── ssl_tls1_blog.markli.cn.txt
│   ├── ssl_tls1_docker.markli.cn.txt
│   ├── ssl_tls1_memos.markli.cn.txt
│   ├── ssl_tls1_monitor.markli.cn.txt
│   ├── ssl_tls1_opms.markli.cn.txt
│   ├── ssl_tls1_ql.markli.cn.txt
│   ├── ssl_tls1_rd.markli.cn.txt
│   ├── ssl_tls1_syncthing.markli.cn.txt
│   ├── tls1_1-nook.txt
│   ├── tls1_1-ok.txt
│   ├── tls1_2-nook.txt
│   ├── tls1_2-ok.txt
│   ├── tls1_3-nook.txt
│   ├── tls1_3-ok.txt
│   ├── tls1-nook.txt
│   ├── tls1-ok.txt
│   └── true.txt
└── source
    └── markli.cn.conf
```



## 检查域名是否在用
```bash
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh check 
[INFO] blog.markli.cn is Available
[INFO] docker.markli.cn is Available
[INFO] memos.markli.cn is Available
[INFO] monitor.markli.cn is Available
[INFO] opms.markli.cn is Available
[INFO] ql.markli.cn is Available
[INFO] rd.markli.cn is Available
[INFO] syncthing.markli.cn is Available
```



## 查看指定或所有域名支持哪些TLS协议
```bash
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh filter all 
./output/ssl_tls1_1_blog.markli.cn.txt nook
./output/ssl_tls1_1_docker.markli.cn.txt nook
./output/ssl_tls1_1_memos.markli.cn.txt nook
./output/ssl_tls1_1_monitor.markli.cn.txt nook
./output/ssl_tls1_1_opms.markli.cn.txt nook
./output/ssl_tls1_1_ql.markli.cn.txt nook
./output/ssl_tls1_1_rd.markli.cn.txt nook
./output/ssl_tls1_1_syncthing.markli.cn.txt nook
./output/ssl_tls1_2_blog.markli.cn.txt ok
./output/ssl_tls1_2_docker.markli.cn.txt ok
./output/ssl_tls1_2_memos.markli.cn.txt ok
./output/ssl_tls1_2_monitor.markli.cn.txt ok
./output/ssl_tls1_2_opms.markli.cn.txt ok
./output/ssl_tls1_2_ql.markli.cn.txt ok
./output/ssl_tls1_2_rd.markli.cn.txt ok
./output/ssl_tls1_2_syncthing.markli.cn.txt ok
./output/ssl_tls1_3_blog.markli.cn.txt ok
./output/ssl_tls1_3_docker.markli.cn.txt ok
./output/ssl_tls1_3_memos.markli.cn.txt ok
./output/ssl_tls1_3_monitor.markli.cn.txt ok
./output/ssl_tls1_3_opms.markli.cn.txt ok
./output/ssl_tls1_3_ql.markli.cn.txt ok
./output/ssl_tls1_3_rd.markli.cn.txt ok
./output/ssl_tls1_3_syncthing.markli.cn.txt ok
./output/ssl_tls1_blog.markli.cn.txt nook
./output/ssl_tls1_docker.markli.cn.txt nook
./output/ssl_tls1_memos.markli.cn.txt nook
./output/ssl_tls1_monitor.markli.cn.txt nook
./output/ssl_tls1_opms.markli.cn.txt nook
./output/ssl_tls1_ql.markli.cn.txt nook
./output/ssl_tls1_rd.markli.cn.txt nook
./output/ssl_tls1_syncthing.markli.cn.txt nook
[root@hw-blog test-ssl-version]# ./openssl_client_test.sh filter blog.markli.cn
./output/ssl_tls1_1_blog.markli.cn.txt nook
./output/ssl_tls1_2_blog.markli.cn.txt ok
./output/ssl_tls1_3_blog.markli.cn.txt ok
./output/ssl_tls1_blog.markli.cn.txt nook
```
