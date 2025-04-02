# 脚本作用
* 此脚本用于一键生成iptables规则，针对本机和容器暴露的服务端口进行防护，在安装docker环境的服务器亦可使用



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
1e74d2ef4341   harborrepo.domain.com/base/frontend/ops_nginx:alpine   "/docker-entrypoint.…"   2 hours ago    Up 2 hours    0.0.0.0:8081->80/tcp   nginx02
2f5ccb866c4b   harborrepo.domain.com/base/frontend/ops_nginx:alpine   "/docker-entrypoint.…"   23 hours ago   Up 23 hours   0.0.0.0:8080->80/tcp   nginx

```



# 配置访问IP黑白名单
配置本地主机和容器的服务端口、黑名单地址、白名单地址，其中CONTAINER_PORTS变量的分隔符`:`之前表示容器暴露的宿主机端口，分隔符`:`之后表示容器内部的服务端口
```bash
container_var(){
        # HOST_PORT:CONTAINER_PORT
        declare -g -a CONTAINER_PORTS=('8080:80 8081:80')
        declare -g -a CONTAINER_IP_BLACK_LIST=('10.10.13.0/24' '192.168.2.122')
        declare -g -a CONTAINER_IP_WHITE_LIST=('192.168.2.219 10.10.13.236')
}

host_var(){
        declare -g -a LOCALHOST_PORTS=('9100 8088')
        declare -g -a LOCALHOST_IP_BLACK_LIST=('10.10.13.0/24' '192.168.2.0/24')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('192.168.2.219 10.10.13.236')
}
```



# 脚本使用方法
脚本有三个参数，分别是`make`,`remove`,`show`,分别表示生成规则、删除规则和查看当前iptables规则
在`make`,`remove`命令中，使用子命令`host`,`container`可以对host和container的iptables规则单独进行生成或删除，`all`表示对host和container同时生成或删除


## 查看帮助信息
```bash
[root@test /shell]# ./make_iptables_rule.sh
Usage ./make_iptables_rule.sh ACTION | show
where  ACTION := { make | remove } { host | container | all }

[root@test /shell]# ./make_iptables_rule.sh show
##########################
[ HOST INFO ] LOCALHOST_PORTS: 9100 8088, LOCALHOST_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.0/24, LOCALHOST_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
[ CONTAINER INFO ] CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): 8080:80 8081:80, CONTAINER_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.122, CONTAINER_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
##########################


[INFO] host iptables rules
##########################
Chain INPUT (policy ACCEPT 432K packets, 47M bytes)
num   pkts bytes target     prot opt in     out     source               destination
##########################


[INFO] container iptables rules
##########################
Chain DOCKER (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
2      134  7088 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80
3       24  1280 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.17.0.3:80

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1      332 43699 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
2      332 43699 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3      158 19888 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
4       29  1516 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
5      145 22295 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
6        0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
##########################
```



## 生成iptables规则
```bash
[root@test-backend02 /shell]# ./make_iptables_rule.sh make all
####################
       HOST
####################
[INFO] make iptalbles rule: 192.168.2.219 -> 0.0.0.0:9100 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.236 -> 0.0.0.0:9100 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] make iptalbles rule: 192.168.2.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] make iptalbles rule: 192.168.2.219 -> 0.0.0.0:8088 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.236 -> 0.0.0.0:8088 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] make iptalbles rule: 192.168.2.0/24 -> 0.0.0.0:8088 DROP successful
####################
     CONTAINER
####################
[INFO] make iptalbles rule: 192.168.2.219 -> 172.17.0.2:80 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.236 -> 172.17.0.2:80 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.0/24 -> 172.17.0.2:80 DROP successful
[INFO] make iptalbles rule: 192.168.2.122 -> 172.17.0.2:80 DROP successful
[INFO] make iptalbles rule: 192.168.2.219 -> 172.17.0.3:80 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.236 -> 172.17.0.3:80 ACCEPT successful
[INFO] make iptalbles rule: 10.10.13.0/24 -> 172.17.0.3:80 DROP successful
[INFO] make iptalbles rule: 192.168.2.122 -> 172.17.0.3:80 DROP successful
```



## 查看当前iptables中INPUT、FORWARD、DOCKER三个chain的规则
```bash
[root@test-backend02 /shell]# ./make_iptables_rule.sh show
##########################
[ HOST INFO ] LOCALHOST_PORTS: 9100 8088, LOCALHOST_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.0/24, LOCALHOST_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
[ CONTAINER INFO ] CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): 8080:80 8081:80, CONTAINER_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.122, CONTAINER_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
##########################


[INFO] host iptables rules
##########################
Chain INPUT (policy ACCEPT 28 packets, 23976 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     tcp  --  *      *       10.10.13.236       0.0.0.0/0            tcp dpt:8088
2        0     0 ACCEPT     tcp  --  *      *       192.168.2.219        0.0.0.0/0            tcp dpt:8088
3        0     0 ACCEPT     tcp  --  *      *       10.10.13.236       0.0.0.0/0            tcp dpt:9100
4        0     0 ACCEPT     tcp  --  *      *       192.168.2.219        0.0.0.0/0            tcp dpt:9100
5        0     0 DROP       tcp  --  *      *       10.10.13.0/24      0.0.0.0/0            tcp dpt:9100
6        0     0 DROP       tcp  --  *      *       192.168.2.0/24       0.0.0.0/0            tcp dpt:9100
7        0     0 DROP       tcp  --  *      *       10.10.13.0/24      0.0.0.0/0            tcp dpt:8088
8        0     0 DROP       tcp  --  *      *       192.168.2.0/24       0.0.0.0/0            tcp dpt:8088
##########################


[INFO] container iptables rules
##########################
Chain DOCKER (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
2      134  7088 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80
3       24  1280 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.17.0.3:80

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     tcp  --  *      *       10.10.13.236       172.17.0.3           tcp dpt:80
2        0     0 ACCEPT     tcp  --  *      *       192.168.2.219        172.17.0.3           tcp dpt:80
3        0     0 ACCEPT     tcp  --  *      *       10.10.13.236       172.17.0.2           tcp dpt:80
4        0     0 ACCEPT     tcp  --  *      *       192.168.2.219        172.17.0.2           tcp dpt:80
5        0     0 DROP       tcp  --  *      *       10.10.13.0/24      172.17.0.2           tcp dpt:80
6        0     0 DROP       tcp  --  *      *       192.168.2.122        172.17.0.2           tcp dpt:80
7        0     0 DROP       tcp  --  *      *       10.10.13.0/24      172.17.0.3           tcp dpt:80
8        0     0 DROP       tcp  --  *      *       192.168.2.122        172.17.0.3           tcp dpt:80
9      332 43699 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
10     332 43699 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
11     158 19888 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
12      29  1516 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
13     145 22295 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
14       0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
##########################
```



## 移除所添加的iptables规则
```bash
[root@test-backend02 /shell]# ./make_iptables_rule.sh remove all
####################
       HOST
####################
[INFO] remove iptalbles rule: 10.10.13.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] remove iptalbles rule: 192.168.2.0/24 -> 0.0.0.0:9100 DROP successful
[INFO] remove iptalbles rule: 192.168.2.219 -> 0.0.0.0:9100 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.236 -> 0.0.0.0:9100 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] remove iptalbles rule: 192.168.2.0/24 -> 0.0.0.0:8088 DROP successful
[INFO] remove iptalbles rule: 192.168.2.219 -> 0.0.0.0:8088 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.236 -> 0.0.0.0:8088 ACCEPT successful
####################
     CONTAINER
####################
[INFO] remove iptalbles rule: 10.10.13.0/24 -> 172.17.0.2:80 DROP successful
[INFO] remove iptalbles rule: 192.168.2.122 -> 172.17.0.2:80 DROP successful
[INFO] remove iptalbles rule: 192.168.2.219 -> 172.17.0.2:80 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.236 -> 172.17.0.2:80 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.0/24 -> 172.17.0.3:80 DROP successful
[INFO] remove iptalbles rule: 192.168.2.122 -> 172.17.0.3:80 DROP successful
[INFO] remove iptalbles rule: 192.168.2.219 -> 172.17.0.3:80 ACCEPT successful
[INFO] remove iptalbles rule: 10.10.13.236 -> 172.17.0.3:80 ACCEPT successful
```



## 查看当前iptables中INPUT、FORWARD、DOCKER三个chain的规则
```bash
[root@test-backend02 /shell]# ./make_iptables_rule.sh show
##########################
[ HOST INFO ] LOCALHOST_PORTS: 9100 8088, LOCALHOST_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.0/24, LOCALHOST_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
[ CONTAINER INFO ] CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): 8080:80 8081:80, CONTAINER_IP_BLACK_LIST: 10.10.13.0/24 192.168.2.122, CONTAINER_IP_WHITE_LIST: 192.168.2.219 10.10.13.236
##########################


[INFO] host iptables rules
##########################
Chain INPUT (policy ACCEPT 30 packets, 25345 bytes)
num   pkts bytes target     prot opt in     out     source               destination
##########################


[INFO] container iptables rules
##########################
Chain DOCKER (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
2      134  7088 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80
3       24  1280 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.17.0.3:80

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1      332 43699 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
2      332 43699 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3      158 19888 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
4       29  1516 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
5      145 22295 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
6        0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
##########################
```



# FAQ



## 执行make无法完全执行成功
```bash
[root@jenkins-slave /shell/iptables]# ./make_iptables_rule.sh show
........
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1        0     0 DROP       tcp  --  *      *       172.16.30.0/24       172.19.0.2           tcp dpt:9848
2        4   240 DROP       tcp  --  *      *       10.10.13.0/24      172.19.0.2           tcp dpt:9848
3     416M  438G DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
4     416M  438G DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
5      99M  108G ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
6    4033K  242M DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0           


[root@jenkins-slave /shell/iptables]# ./make_iptables_rule.sh make container 
[INFO] CONTAINER:
[INFO] (10.10.13.0/24 -> 172.19.0.2:9848 DROP) iptables rule already exists!!!
[INFO] (172.16.30.0/24 -> 172.19.0.2:9848 DROP) iptables rule already exists!!!
[INFO] (10.10.13.236 -> 172.19.0.2:9848 ACCEPT) iptables rule not exists!!!
[INFO] (10.10.13.237 -> 172.19.0.2:9848 ACCEPT) iptables rule not exists!!!
```
> 原因：脚本第一次执行时只添加了黑名单，而未添加白名单，所以第二次执行时，脚本会认为黑名单已经存在，而不会添加白名单。
> 解决方法：手动添加白名单规则，或者先执行一次`./make_iptables_rule.sh remove container`命令。