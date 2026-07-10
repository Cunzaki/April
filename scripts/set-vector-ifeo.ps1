$ErrorActionPreference = "Continue"
$exe = "C:\Users\Cunza\Desktop\vector.exe"
$ifeoParent = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vector.exe"
$ifeo = Join-Path $ifeoParent "PerfOptions"

if (-not (Test-Path $ifeoParent)) {
    New-Item -Path $ifeoParent -Force | Out-Null
}
if (-not (Test-Path $ifeo)) {
    New-Item -Path $ifeo -Force | Out-Null
}
New-ItemProperty -Path $ifeo -Name "CpuPriorityClass" -Value 3 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $ifeo -Name "IoPriority" -Value 3 -PropertyType DWord -Force | Out-Null
Write-Host "IFEO PerfOptions written for vector.exe"
