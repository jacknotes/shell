$scriptPath = Split-Path -Path $PSCommandPath
$today = Get-Date
$path = "{0:d4}{1:d2}{2:d2}" -f $today.Year,$today.Month,$today.Day
$backupPath = Join-Path -Path $scriptPath -ChildPath $path

if(Test-Path -Path $backupPath){
    Write-Information -MessageData "Backup Directory Exist!!!"
}else{
    $null = New-Item -ItemType Directory -Path $backupPath
    $null = Backup-GPO -All -Path $backupPath
}