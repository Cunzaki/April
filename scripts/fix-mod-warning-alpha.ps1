Add-Type -AssemblyName System.Drawing

$src = Join-Path $PSScriptRoot "..\assets\mod_warning_src.png"
$dst = Join-Path $PSScriptRoot "..\assets\mod_warning.png"
$size = 128

if (-not (Test-Path $src)) {
    Write-Error "Missing source image: $src"
    exit 1
}

$img = [System.Drawing.Image]::FromFile($src)
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, 0, 0, $size, $size)
$g.Dispose()
$img.Dispose()

$threshold = 230
for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -ge $threshold -and $c.G -ge $threshold -and $c.B -ge $threshold) {
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $c.R, $c.G, $c.B))
        }
    }
}

$bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Saved transparent PNG: $dst ($((Get-Item $dst).Length) bytes)"
