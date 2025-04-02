<#
前提：
  1.该脚本需要模块DnsServer
  2.执行脚本的主机与DNS服务器保持网络连接
  3.执行脚本的用户需要在远程DNS服务器上有相应权限
使用方式：
  利用任务计划程序来调用脚本，参数：-File <脚本文件路径> -ComputerName <远程DNS服务器FQDN> -ErrorAction SilentlyContinue
结果：
  1.脚本执行后，会在远程DNS服务器上的DNS目录（默认为：c:\windows\system32\dns）生成DNS区域的备份文件（AD类型）
  2.每天每个区域只能有一个文件，之后的同名文件会创建失败
恢复DNS区域：
  1.将备份文件复制到DNS服务器上的DNS目录（默认为：c:\windows\system32\dns）
  2.执行命令：dnscmd <远程DNS服务器FQDN> /ZoneAdd <ZoneName> /Primary /file <备份的区域文件名> /load
  3.打开DNS服务器管理器，将相应区域的类型更改为：Active Directory 集成区域，动态类型更改为：安全
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ComputerName
)

$Prefix = "Dns - " + (Get-Date -Format "yyyyMMdd") + " - " 
$Suffix = ".bak"
#$Zones = Get-DnsServerZone -ComputerName $ComputerName
$Zones = (Get-WmiObject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -ComputerName $ComputerName).Name

foreach($zone in $Zones){
    #$zonename = $zone.ZoneName
    $zonename = $zone
    if ($zonename -eq "TrustAnchors"){
        #$zonename = "_msdcs.domain.com"
    }
    $filename = $Prefix + $zonename + $Suffix
    #Export-DnsServerZone -FileName $filename -Name $zonename -ComputerName $ComputerName
    dnscmd $ComputerName /ZoneExport $zonename $filename
}