$ErrorActionPreference = "Continue"
$exe = "C:\Users\Cunza\Desktop\vector.exe"

function Say([string]$tag, [string]$msg) {
    Write-Host ("[{0}] {1}" -f $tag, $msg)
}

if (-not (Test-Path -LiteralPath $exe)) {
    Say "FAIL" "vector.exe not found at $exe"
    exit 1
}
Say "OK" "Found $exe"

# High-performance GPU (Windows Graphics Settings)
$gpuKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
if (-not (Test-Path $gpuKey)) {
    New-Item -Path $gpuKey -Force | Out-Null
}
New-ItemProperty -Path $gpuKey -Name $exe -Value "GpuPreference=2;" -PropertyType String -Force | Out-Null
Say "OK" "GPU preference set to High Performance (GpuPreference=2)"

# IFEO PerfOptions - High CPU + High I/O on every launch
$ifeo = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vector.exe\PerfOptions"
try {
    if (-not (Test-Path $ifeo)) {
        New-Item -Path $ifeo -Force | Out-Null
    }
    # CpuPriorityClass: 3 = High
    New-ItemProperty -Path $ifeo -Name "CpuPriorityClass" -Value 3 -PropertyType DWord -Force | Out-Null
    # IoPriority: 3 = High
    New-ItemProperty -Path $ifeo -Name "IoPriority" -Value 3 -PropertyType DWord -Force | Out-Null
    Say "OK" "IFEO PerfOptions: CpuPriorityClass=High, IoPriority=High"
} catch {
    Say "WARN" ("IFEO needs admin: {0}" -f $_.Exception.Message)
}

# Raise priority of any currently running vector.exe
$procs = Get-Process -Name "vector" -ErrorAction SilentlyContinue
if ($procs) {
    foreach ($p in $procs) {
        try {
            $p.PriorityClass = "High"
            Say "OK" ("Set running PID {0} PriorityClass=High" -f $p.Id)
        } catch {
            Say "WARN" ("Could not set priority on PID {0}: {1}" -f $p.Id, $_.Exception.Message)
        }
    }
} else {
    Say "WARN" "vector.exe is not running - IFEO priority applies on next launch"
}

# Verify
$gpuVal = (Get-ItemProperty -Path $gpuKey -Name $exe -ErrorAction SilentlyContinue).$exe
Say "OK" ("Verify GPU reg: {0}" -f $gpuVal)
if (Test-Path $ifeo) {
    $props = Get-ItemProperty -Path $ifeo -ErrorAction SilentlyContinue
    Say "OK" ("Verify IFEO CpuPriorityClass={0} IoPriority={1}" -f $props.CpuPriorityClass, $props.IoPriority)
}

Write-Host ""
Write-Host "Done. Restart vector.exe if it was already open so GPU preference takes effect."
