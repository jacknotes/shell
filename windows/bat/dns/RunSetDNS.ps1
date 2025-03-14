# 设置用户名和密码
$user = "domain\user"
$pass = "password"

# 设置 .bat 文件的完整路径
$batFilePath = "E:\dns\SetDNS.bat"

# 确保 .bat 文件存在
if (-Not (Test-Path $batFilePath)) {
    Write-Host "Error: $batFilePath not found."
    exit
}

# 创建凭据对象
$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
$credential = New-Object PSCredential $user, $securePass

# 使用 Start-Process 运行命令
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $batFilePath" -Credential $credential -NoNewWindow -Wait

Set-ExecutionPolicy -ExecutionPolicy Default -Force