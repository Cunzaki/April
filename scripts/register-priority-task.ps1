$ErrorActionPreference = "Continue"
$taskName = "VectorHighPriority"
$script = "c:\Users\Cunza\Desktop\Projects\Vector Scripts\April\scripts\vector-priority-keeper.ps1"
$arg = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $script + '"'
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arg
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName, State | Format-List
Write-Host "Priority keeper scheduled task registered and started."
