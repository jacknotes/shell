# 脚本作用
* 此脚本用于一键生成iptables规则，针对本机和容器暴露的服务端口进行防护，在安装docker环境的服务器亦可使用
* 此脚本建议第一次使用，后面再次使用建议手动插入Iptables规则，如果改变脚本中的地址信息后，使用此脚本的DROP规则可能会覆盖老的ACCEPT规则，慎用



# 本地运行的服务
```bash
[root@test /shell]# ss -tnl
State      Recv-Q Send-Q                                                                       Local Address:Port                                                                                      Peer Address:Port
LISTEN     0      128                                                                                      *:6443                                                                                                 *:*
LISTEN     0      128                                                                                      *:80                                                                                                   *:*
LISTEN     0      128                                                                                      *:22                                                                                                   *:*
LISTEN     0      128                                                                                      *:8088                                                                                                 *:*
LISTEN     0      128                                                                              127.0.0.1:8089                                                                                                 *:*
LISTEN     0      128                                                                                      *:443                                                                                                  *:*
LISTEN     0      128                                                                                   [::]:9100                                                                                              [::]:*
LISTEN     0      128                                                                                   [::]:8080                                                                                              [::]:*
LISTEN     0      128                                                                                   [::]:8081                                                                                              [::]:*
LISTEN     0      128                                                                                   [::]:22                                                                                                [::]:*
[root@test /shell]# docker ps -a
CONTAINER ID   IMAGE                                              COMMAND                  CREATED        STATUS        PORTS                  NAMES
1e74d2ef4341   harborrepo.hs.com/base/frontend/ops_nginx:alpine   "/docker-entrypoint.…"   2 hours ago    Up 2 hours    0.0.0.0:8081->80/tcp   nginx02
2f5ccb866c4b   harborrepo.hs.com/base/frontend/ops_nginx:alpine   "/docker-entrypoint.…"   23 hours ago   Up 23 hours   0.0.0.0:8080->80/tcp   nginx

```



# 配置访问IP黑白名单
配置本地主机和容器的服务端口、黑名单地址、白名单地址，其中CONTAINER_PORTS变量的分隔符`:`之前表示容器暴露的宿主机端口，分隔符`:`之后表示容器内部的服务端口
```bash
container_var(){
        # HOST_PORT:CONTAINER_PORT
        declare -g -a CONTAINER_PORTS=('8080:80 8081:80')
        declare -g -a CONTAINER_IP_BLACK_LIST=('192.168.13.0/24' '172.168.2.122')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('172.168.2.219 192.168.13.236')
}

host_var(){
        declare -g -a LOCALHOST_PORTS=('9100 8088 ')
        declare -g -a LOCALHOST_IP_BLACK_LIST=('192.168.13.0/24' '172.168.2.0/24')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('172.168.2.219 192.168.13.236')
}
```



# 脚本使用方法
脚本有三个参数，分别是`make`,`remove`,`show`,分别表示生成规则、删除规则和查看当前iptables规则



## 查看帮助信息
```bash
[root@test /shell]# ./make_iptables_rule.sh
Usage ./make_iptables_rule.sh [ make | remove | show ]
```



## 生成iptables规则
```bash
[root@test /shell]# ./make_iptables_rule.sh make
[INFO] CONTAINER:
[INFO] make iptalbles rule: 192.168.13.0/24 -> 172.17.0.2:80 DROP successful
[INFO] make iptalbles rule: 172.168.2.122 -> 172.17.0.2:80 DROP successful
[INFO] make iptalbles rule: 192.168.13.0/24 -> 172.17.0.3:80 DROP successful
[INFO] make iptalbles rule: 172.168.2.122 -> 172.17.0.3:80 DROP successful
[INFO] LOCALHOST:
[INFO] make iptalbles rule: 192.168.13.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] make iptalbles rule: 172.168.2.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] make iptalbles rule: 172.168.2.219 -> 0.0.0.0:9100 ACCEPT successful
[INFO] make iptalbles rule: 192.168.13.236 -> 0.0.0.0:9100 ACCEPT successful
[INFO] make iptalbles rule: 192.168.13.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] make iptalbles rule: 172.168.2.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] make iptalbles rule: 172.168.2.219 -> 0.0.0.0:8088 ACCEPT successful
[INFO] make iptalbles rule: 192.168.13.236 -> 0.0.0.0:8088 ACCEPT successful
```



## 查看当前iptables中INPUT、FORWARD、DOCKER三个chain的规则
```bash
[root@test /shell]# ./make_iptables_rule.sh show
##########################
[INFO] execute host info: LOCALHOST_PORTS: 9100 8088 , LOCALHOST_IP_BLACK_LIST: 192.168.13.0/24 172.168.2.0/24, LOCALHOST_IP_WHITE_LIST: 172.168.2.219 192.168.13.236
[INFO] execute container info: CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): 8080:80 8081:80, CONTAINER_IP_BLACK_LIST: 192.168.13.0/24 172.168.2.122, CONTAINER_IP_WHITE_LIST:
##########################


[INFO] host iptables rules
##########################
Chain INPUT (policy ACCEPT 349 packets, 32894 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     tcp  --  *      *       192.168.13.236       0.0.0.0/0            tcp dpt:8088
2        0     0 ACCEPT     tcp  --  *      *       172.168.2.219        0.0.0.0/0            tcp dpt:8088
3        0     0 DROP       tcp  --  *      *       172.168.2.0/24       0.0.0.0/0            tcp dpt:8088
4        0     0 DROP       tcp  --  *      *       192.168.13.0/24      0.0.0.0/0            tcp dpt:8088
5        0     0 ACCEPT     tcp  --  *      *       192.168.13.236       0.0.0.0/0            tcp dpt:9100
6        0     0 ACCEPT     tcp  --  *      *       172.168.2.219        0.0.0.0/0            tcp dpt:9100
7        0     0 DROP       tcp  --  *      *       172.168.2.0/24       0.0.0.0/0            tcp dpt:9100
8        0     0 DROP       tcp  --  *      *       192.168.13.0/24      0.0.0.0/0            tcp dpt:9100
##########################


[INFO] container iptables rules
##########################
Chain DOCKER (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
2      131  6932 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80
3       24  1280 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.17.0.3:80

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 DROP       tcp  --  *      *       172.168.2.122        172.17.0.3           tcp dpt:80
2        0     0 DROP       tcp  --  *      *       192.168.13.0/24      172.17.0.3           tcp dpt:80
3        0     0 DROP       tcp  --  *      *       172.168.2.122        172.17.0.2           tcp dpt:80
4        0     0 DROP       tcp  --  *      *       192.168.13.0/24      172.17.0.2           tcp dpt:80
5      302 40300 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
6      302 40300 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
7      143 17686 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
8       26  1360 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
9      133 21254 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
10       0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
##########################
```



## 移除所添加的iptables规则
```bash
[root@test /shell]# ./make_iptables_rule.sh remove
[INFO] CONTAINER:
[INFO] remove iptalbles rule: 192.168.13.0/24 -> 172.17.0.2:80 DROP successful
[INFO] remove iptalbles rule: 172.168.2.122 -> 172.17.0.2:80 DROP successful
[INFO] remove iptalbles rule: 192.168.13.0/24 -> 172.17.0.3:80 DROP successful
[INFO] remove iptalbles rule: 172.168.2.122 -> 172.17.0.3:80 DROP successful
[INFO] LOCALHOST:
[INFO] remove iptalbles rule: 192.168.13.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] remove iptalbles rule: 172.168.2.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] remove iptalbles rule: 172.168.2.219 -> 0.0.0.0:9100 ACCEPT successful
[INFO] remove iptalbles rule: 192.168.13.236 -> 0.0.0.0:9100 ACCEPT successful
[INFO] remove iptalbles rule: 192.168.13.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] remove iptalbles rule: 172.168.2.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] remove iptalbles rule: 172.168.2.219 -> 0.0.0.0:8088 ACCEPT successful
[INFO] remove iptalbles rule: 192.168.13.236 -> 0.0.0.0:8088 ACCEPT successful
```



## 查看当前iptables中INPUT、FORWARD、DOCKER三个chain的规则
```bash
[root@test /shell]# ./make_iptables_rule.sh show
##########################
[INFO] execute host info: LOCALHOST_PORTS: 9100 8088 , LOCALHOST_IP_BLACK_LIST: 192.168.13.0/24 172.168.2.0/24, LOCALHOST_IP_WHITE_LIST: 172.168.2.219 192.168.13.236
[INFO] execute container info: CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): 8080:80 8081:80, CONTAINER_IP_BLACK_LIST: 192.168.13.0/24 172.168.2.122, CONTAINER_IP_WHITE_LIST:
##########################


[INFO] host iptables rules
##########################
Chain INPUT (policy ACCEPT 25 packets, 4840 bytes)
num   pkts bytes target     prot opt in     out     source               destination
##########################


[INFO] container iptables rules
##########################
Chain DOCKER (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
2      131  6932 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80
3       24  1280 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.17.0.3:80

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1      302 40300 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
2      302 40300 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3      143 17686 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
4       26  1360 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
5      133 21254 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
6        0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
##########################
```