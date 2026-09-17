<#
.SYNOPSIS
    Kurumsal Windows Sunucu Sağlık ve Durum Raporlayıcısı (HTML Raporu).
.DESCRIPTION
    Sunucunun disk doluluk oranlarını (C, D, E sürücüleri), RAM kullanımını,
    sistem çalışma süresini (Uptime) ve kritik Windows servislerini denetleyip
    renk kodlu, responsive kurumsal bir HTML durum raporu üretir.
.PARAMETER OutputHtmlPath
    Oluşturulacak HTML raporunun kaydedileceği dosya yolu.
.EXAMPLE
    .\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
.NOTES
    Yazar : Samet Çakmak
    Sürüm : 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputHtmlPath = ".\ServerHealthReport.html"
)

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  WINDOWS SUNUCU SAĞLIK VE DURUM RAPORLAYICISI" -ForegroundColor Green
Write-Host "  Hazırlayan: Samet Çakmak" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$serverName = $env:COMPUTERNAME
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 1. Disk Durumu Sorgusu
Write-Host "[1/4] Disk sürücüleri analiz ediliyor..." -ForegroundColor Gray
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue

$diskRows = ""
if ($disks) {
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 1)
        $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1)
        $usedGB  = [math]::Round($totalGB - $freeGB, 1)
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 1)

        # Renk Kodu Mantığı: %10 altı Kırmızı, %20 altı Sarı, üzeri Yeşil
        if ($percentFree -lt 10) {
            $badgeColor = "#EF4444" # Kırmızı (Kritik)
            $badgeText  = "KRİTİK (%$percentFree Boş)"
        } elseif ($percentFree -lt 20) {
            $badgeColor = "#F59E0B" # Sarı (Uyarı)
            $badgeText  = "DİKKAT (%$percentFree Boş)"
        } else {
            $badgeColor = "#10B981" # Yeşil (Sağlıklı)
            $badgeText  = "SAĞLIKLI (%$percentFree Boş)"
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
    $diskRows = "<tr><td colspan='5'>Disk bilgisi okunamadı.</td></tr>"
}

# 2. RAM (Bellek) Kullanımı
Write-Host "[2/4] Bellek (RAM) kullanımı hesaplanıyor..." -ForegroundColor Gray
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeRAM  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 1)
$percentRAMUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

# 3. Uptime (Çalışma Süresi)
Write-Host "[3/4] Sistem çalışma süresi hesaplanıyor..." -ForegroundColor Gray
$uptimeStr = "N/A"
if ($os.LastBootUpTime) {
    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeStr = "$($uptime.Days) Gün, $($uptime.Hours) Saat, $($uptime.Minutes) Dakika"
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
        $sLabel = if ($status -eq "Running") { "ÇALIŞIYOR" } else { "DURMUŞ!" }
        $dispName = $srv.DisplayName
    } else {
        $status = "NotInstalled"
        $sColor = "#64748B"
        $sLabel = "YÜKLÜ DEĞİL"
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

# 5. Modern HTML Şablonu Oluşturma
$htmlContent = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>Sunucu Sağlık Raporu - $serverName</title>
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
                <h1>🖥️ Sunucu Sağlık ve Durum Raporu</h1>
                <div style="font-size: 14px; color: #2563EB; font-weight: 600; margin-top: 5px;">Sunucu: $serverName</div>
            </div>
            <div class="meta">
                <div><strong>Rapor Tarihi:</strong> $reportTime</div>
                <div><strong>Hazırlayan:</strong> Samet Çakmak</div>
            </div>
        </div>

        <div class="metric-grid">
            <div class="metric-card">
                <h3>RAM Kullanımı</h3>
                <p>%$percentRAMUsed ($usedRAM / $totalRAM GB)</p>
            </div>
            <div class="metric-card">
                <h3>Sistem Uptime</h3>
                <p style="font-size: 15px;">$uptimeStr</p>
            </div>
            <div class="metric-card">
                <h3>Denetlenen Sürücü</h3>
                <p>$($disks.Count) Adet</p>
            </div>
        </div>

        <h2>💾 Disk Sürücüleri ve Doluluk Oranları</h2>
        <table>
            <thead>
                <tr>
                    <th>Sürücü</th>
                    <th>Toplam Boyut</th>
                    <th>Kullanılan</th>
                    <th>Boş Alan</th>
                    <th>Durum</th>
                </tr>
            </thead>
            <tbody>
                $diskRows
            </tbody>
        </table>

        <h2>⚙️ Kritik Windows Servisleri</h2>
        <table>
            <thead>
                <tr>
                    <th>Servis Adı</th>
                    <th>Açıklama</th>
                    <th>Durum</th>
                </tr>
            </thead>
            <tbody>
                $serviceRows
            </tbody>
        </table>

        <div class="footer">
            Bu rapor <strong>PowerShell Sysadmin Toolkit</strong> (Samet Çakmak) otomasyon aracı tarafından oluşturulmuştur.
        </div>
    </div>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $OutputHtmlPath -Encoding UTF8
Write-Host "`n[✓] Sağlık raporu başarıyla oluşturuldu: $OutputHtmlPath" -ForegroundColor Green
Write-Host "    (Tarayıcınızda açıp doğrudan inceleyebilirsiniz.)`n" -ForegroundColor DarkGray
