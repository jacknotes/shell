# 说明
此脚本是jenkins自由风格的流水线脚本，用于在Jenkins中构建基于Docker的微服务应用，并最终将其部署到Kubernetes集群中。


* 有master和slave节点2个脚本，不同之处在于`JENKINS_USER`不同，由于操作系统用户不同所以需要修改脚本，建议用于配置一致
* 因为性能瓶颈问题需要扩展节点，所以有了slave节点脚本