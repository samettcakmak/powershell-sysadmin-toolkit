<#
.SYNOPSIS
    Kurumsal Windows Sunucu Saglik ve Durum Raporlayicisi (HTML Raporu).
.DESCRIPTION
    Sunucunun disk doluluk oranlarini (C, D, E suruculeri), RAM kullanimini,
    sistem calisma suresini (Uptime) ve kritik Windows servislerini denetleyip
    renk kodlu, responsive kurumsal bir HTML durum raporu uretir.
.PARAMETER OutputHtmlPath
    Olusturulacak HTML raporunun kaydedilecegi dosya yolu.
.EXAMPLE
    .\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
.NOTES
    Yazar : Samet Cakmak
    Surum : 1.1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputHtmlPath = ".\ServerHealthReport.html"
)

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  WINDOWS SUNUCU SAGLIK VE DURUM RAPORLAYICISI" -ForegroundColor Green
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$serverName = $env:COMPUTERNAME
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 1. Disk Durumu Sorgusu
Write-Host "[1/4] Disk suruculeri analiz ediliyor..." -ForegroundColor Gray
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue

$diskRows = ""
if ($disks) {
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 1)
        $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1)
        $usedGB  = [math]::Round($totalGB - $freeGB, 1)
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 1)

        if ($percentFree -lt 10) {
            $badgeColor = "#EF4444"
            $badgeText  = "KRITIK (%$percentFree Bos)"
        } elseif ($percentFree -lt 20) {
            $badgeColor = "#F59E0B"
            $badgeText  = "DIKKAT (%$percentFree Bos)"
        } else {
            $badgeColor = "#10B981"
            $badgeText  = "SAGLIKLI (%$percentFree Bos)"
        }

        $diskRows += @"
        <tr>
            <td><strong>$($d.DeviceID)</strong></td>
            <td>$totalGB GB</td>
            <td>$usedGB GB</td>
            <td>$freeGB GB</td>
            <td><span class="badge" style="background-color: $badgeColor;">$badgeText</span></td>
        </tr>
"@
    }
} else {
    $diskRows = "<tr><td colspan='5'>Disk bilgisi okunamadi.</td></tr>"
}

# 2. RAM (Bellek) Kullanimi
Write-Host "[2/4] Bellek (RAM) kullanimi hesaplaniyor..." -ForegroundColor Gray
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeRAM  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 1)
$percentRAMUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

# 3. Uptime (Calisma Suresi)
Write-Host "[3/4] Sistem calisma suresi hesaplaniyor..." -ForegroundColor Gray
$uptimeStr = "N/A"
if ($os.LastBootUpTime) {
    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeStr = "$($uptime.Days) Gun, $($uptime.Hours) Saat, $($uptime.Minutes) Dakika"
}

# 4. Kritik Windows Servisleri
Write-Host "[4/4] Kritik servisler denetleniyor..." -ForegroundColor Gray
$criticalServices = @("Spooler", "LanmanServer", "W32Time", "WinRM")
$serviceRows = ""

foreach ($sName in $criticalServices) {
    $srv = Get-Service -Name $sName -ErrorAction SilentlyContinue
    if ($srv) {
        $status = $srv.Status
        $sColor = if ($status -eq "Running") { "#10B981" } else { "#EF4444" }
        $sLabel = if ($status -eq "Running") { "CALISIYOR" } else { "DURMUS!" }
        $dispName = $srv.DisplayName
    } else {
        $status = "NotInstalled"
        $sColor = "#64748B"
        $sLabel = "YUKLU DEGIL"
        $dispName = $sName
    }

    $serviceRows += @"
    <tr>
        <td><strong>$sName</strong></td>
        <td>$dispName</td>
        <td><span class="badge" style="background-color: $sColor;">$sLabel</span></td>
    </tr>
"@
}

# 5. Modern HTML Sablonu Olusturma
$htmlContent = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>Sunucu Saglik Raporu - $serverName</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #F8FAFC; color: #1E293B; margin: 0; padding: 25px; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.07); border: 1px solid #E2E8F0; }
        .header { border-bottom: 2px solid #E2E8F0; padding-bottom: 15px; margin-bottom: 25px; display: flex; justify-content: space-between; align-items: flex-end; }
        .header h1 { margin: 0; font-size: 24px; color: #0F172A; }
        .header .meta { font-size: 13px; color: #64748B; text-align: right; }
        .metric-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 30px; }
        .metric-card { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 15px; text-align: center; }
        .metric-card h3 { margin: 0 0 8px 0; font-size: 13px; color: #64748B; text-transform: uppercase; }
        .metric-card p { margin: 0; font-size: 20px; font-weight: bold; color: #0F172A; }
        h2 { font-size: 17px; color: #1E293B; margin-top: 25px; margin-bottom: 12px; border-left: 4px solid #2563EB; padding-left: 10px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 25px; font-size: 14px; }
        th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #E2E8F0; }
        th { background: #F1F5F9; color: #475569; font-weight: 600; }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 20px; color: white; font-size: 11px; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 15px; border-top: 1px solid #E2E8F0; font-size: 12px; color: #94A3B8; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>Sunucu Saglik ve Durum Raporu</h1>
                <div style="font-size: 14px; color: #2563EB; font-weight: 600; margin-top: 5px;">Sunucu: $serverName</div>
            </div>
            <div class="meta">
                <div><strong>Rapor Tarihi:</strong> $reportTime</div>
                <div><strong>Hazirlayan:</strong> Samet Cakmak</div>
            </div>
        </div>

        <div class="metric-grid">
            <div class="metric-card">
                <h3>RAM Kullanimi</h3>
                <p>%$percentRAMUsed ($usedRAM / $totalRAM GB)</p>
            </div>
            <div class="metric-card">
                <h3>Sistem Uptime</h3>
                <p style="font-size: 15px;">$uptimeStr</p>
            </div>
            <div class="metric-card">
                <h3>Denetlenen Surucu</h3>
                <p>$($disks.Count) Adet</p>
            </div>
        </div>

        <h2>Disk Suruculeri ve Doluluk Oranlari</h2>
        <table>
            <thead>
                <tr>
                    <th>Surucu</th>
                    <th>Toplam Boyut</th>
                    <th>Kullanilan</th>
                    <th>Bos Alan</th>
                    <th>Durum</th>
                </tr>
            </thead>
            <tbody>
                $diskRows
            </tbody>
        </table>

        <h2>Kritik Windows Servisleri</h2>
        <table>
            <thead>
                <tr>
                    <th>Servis Adi</th>
                    <th>Aciklama</th>
                    <th>Durum</th>
                </tr>
            </thead>
            <tbody>
                $serviceRows
            </tbody>
        </table>

        <div class="footer">
            Bu rapor <strong>PowerShell Sysadmin Toolkit</strong> (Samet Cakmak) otomasyon araci tarafindan olusturulmustur.
        </div>
    </div>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $OutputHtmlPath -Encoding UTF8
Write-Host "`n[OK] Saglik raporu basariyla olusturuldu: $OutputHtmlPath" -ForegroundColor Green
Write-Host "    (Tarayicinizda acip dogrudan inceleyebilirsiniz.)`n" -ForegroundColor DarkGray

