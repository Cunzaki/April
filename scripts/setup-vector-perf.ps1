$ErrorActionPreference = "Continue"
$exe = "C:\Users\Cunza\Desktop\vector.exe"
$keeper = "c:\Users\Cunza\Desktop\Projects\Vector Scripts\April\scripts\vector-priority-keeper.ps1"

# GPU high performance
$gpuKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
if (-not (Test-Path $gpuKey)) { New-Item -Path $gpuKey -Force | Out-Null }
New-ItemProperty -Path $gpuKey -Name $exe -Value "GpuPreference=2;" -PropertyType String -Force | Out-Null
Write-Host "[OK] GPU High Performance preference set"

# Auto-start priority keeper at login (HKCU Run - no admin)
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $keeper + '"'
New-ItemProperty -Path $runKey -Name "VectorHighPriority" -Value $cmd -PropertyType String -Force | Out-Null
Write-Host "[OK] Login Run entry VectorHighPriority registered"

# Start keeper now if not already running
$existing = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and $_.CommandLine -like "*vector-priority-keeper.ps1*" }
if (-not $existing) {
    Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", $keeper
    ) -WindowStyle Hidden
    Write-Host "[OK] Priority keeper started"
} else {
    Write-Host "[OK] Priority keeper already running"
}

# Bump any live vector.exe now
$procs = Get-Process -Name "vector" -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    try {
        $p.PriorityClass = "High"
        Write-Host ("[OK] Live PID {0} set to High" -f $p.Id)
    } catch {
        Write-Host ("[WARN] Could not set PID {0}" -f $p.Id)
    }
}

Write-Host ""
Write-Host "GPU preference is set. Restart vector.exe for GPU preference to apply."
Write-Host "Priority keeper will keep vector.exe at High while it runs."
