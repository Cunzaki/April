# Keeps vector.exe at High priority while running (user-level, no admin needed).
# Also re-applies Windows High Performance GPU preference.

$exe = "C:\Users\Cunza\Desktop\vector.exe"
$gpuKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"

if (-not (Test-Path $gpuKey)) {
    New-Item -Path $gpuKey -Force | Out-Null
}
New-ItemProperty -Path $gpuKey -Name $exe -Value "GpuPreference=2;" -PropertyType String -Force | Out-Null

while ($true) {
    $procs = Get-Process -Name "vector" -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            if ($p.PriorityClass -ne "High") {
                $p.PriorityClass = "High"
            }
        } catch {}
    }
    Start-Sleep -Seconds 3
}
