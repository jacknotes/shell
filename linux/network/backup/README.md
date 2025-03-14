# 说明
* 此脚本是备份网络设备的自动化脚本，此脚本包括了：华为交换机、华为防火墙、思科交换机、华三交换机。
* 此脚本依赖TFTP服务器，将所有备份的配置存储于TFTP服务器中
* 使用前请更改脚本文件`backup_network_config.sh`


# 入口脚本文件
```bash
$ vim backup_network_config.sh
# 更改设备列表，第1个参数：执行的脚本类型、第2个参数：设备IP、第3个参数：设备名称
COMMAND_LIST=('/shell/network/huawei-ssh.sh 10.10.10.252 DSW3' '/shell/network/huawei-ssh.sh 10.10.10.253 DSW4' )

# 运行脚本
$ bash ./backup_network_config.sh
```

