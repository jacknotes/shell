# �����û���������
$user = "domain\user"
$pass = "password"

# ���� .bat �ļ�������·��
$batFilePath = "E:\dns\SetDNS.bat"

# ȷ�� .bat �ļ�����
if (-Not (Test-Path $batFilePath)) {
    Write-Host "Error: $batFilePath not found."
    exit
}

# ����ƾ�ݶ���
$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
$credential = New-Object PSCredential $user, $securePass

# ʹ�� Start-Process ��������
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $batFilePath" -Credential $credential -NoNewWindow -Wait

Set-ExecutionPolicy -ExecutionPolicy Default -Force