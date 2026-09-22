<#
.SYNOPSIS
    Kurumsal Windows Sunucu Saglik ve Durum Paneli (Gelisitirilmis HTML Dashboard).
.DESCRIPTION
    Sunucunun CPU, RAM, Disk doluluklarini (gorsel ilerleme cubuklariyla), sistem
    calisma suresini (Uptime), aktif ag kartlarini, en cok bellek tuketen ilk 5 sureci
    ve kritik servisleri denetleyip modern, responsive kurumsal bir HTML dashboard uretir.
.PARAMETER OutputHtmlPath
    Olusturulacak HTML raporunun kaydedilecegi dosya yolu.
.EXAMPLE
    .\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
.NOTES
    Yazar : Samet Cakmak
    Surum : 2.0.0 (Enterprise Dashboard Edition)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputHtmlPath = ".\ServerHealthReport.html"
)

Write-Host "==========================================================" -ForegroundColor Cyan;
Write-Host "  WINDOWS SUNUCU SAGLIK VE PERFORMANS DASHBOARD V2.0" -ForegroundColor Cyan;
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Cyan;
Write-Host "==========================================================" -ForegroundColor Cyan;

$serverName = $env:COMPUTERNAME;
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss";
$overallStatus = "HEALTHY";
$overallStatusText = "SISTEM SAGLIKLI";
$overallStatusColor = "#10B981";

# 1. Isletim Sistemi ve Donanim Bilgileri
Write-Host "[1/6] Isletim sistemi ve donanim tahlili yapiliyor..." -ForegroundColor Gray;
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue;
$osName = if ($os.Caption) { $os.Caption.Trim() } else { "Windows Server" };
$osArch = if ($os.OSArchitecture) { $os.OSArchitecture } else { "64-bit" };
$osVersion = if ($os.Version) { $os.Version } else { "N/A" };

$uptimeStr = "N/A";
$lastBootStr = "N/A";
if ($os.LastBootUpTime) {
    $uptime = (Get-Date) - $os.LastBootUpTime;
    $uptimeStr = "$($uptime.Days) Gun, $($uptime.Hours) Saat, $($uptime.Minutes) Dakika";
    $lastBootStr = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm");
}

# 2. CPU / Islemci Bilgisi ve Yuk
Write-Host "[2/6] Islemci (CPU) durumu denetleniyor..." -ForegroundColor Gray;
$cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1;
$cpuName = if ($cpu.Name) { $cpu.Name.Trim() } else { "Intel / AMD Processor" };
$cpuCores = if ($cpu.NumberOfCores) { $cpu.NumberOfCores } else { 2 };
$cpuThreads = if ($cpu.NumberOfLogicalProcessors) { $cpu.NumberOfLogicalProcessors } else { 4 };
$cpuLoad = if ($null -ne $cpu.LoadPercentage) { $cpu.LoadPercentage } else { 0 };

# 3. RAM (Bellek) Durumu
Write-Host "[3/6] Bellek (RAM) havuzu hesaplaniyor..." -ForegroundColor Gray;
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1);
$freeRAM  = [math]::Round($os.FreePhysicalMemory / 1MB, 1);
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 1);
$percentRAMUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1);

if ($percentRAMUsed -gt 90) {
    $overallStatus = "CRITICAL";
    $overallStatusText = "KRITIK BELLEK YUKU";
    $overallStatusColor = "#EF4444";
} elseif ($percentRAMUsed -gt 80 -and $overallStatus -ne "CRITICAL") {
    $overallStatus = "WARNING";
    $overallStatusText = "YUKSEK BELLEK KULLANIMI";
    $overallStatusColor = "#F59E0B";
}

# 4. Disk Suruculeri ve Gorsel Ilerleme Cubuklari
Write-Host "[4/6] Disk depolama alanlari taraniyor..." -ForegroundColor Gray;
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue;

$diskCards = "";
if ($disks) {
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 1);
        $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1);
        $usedGB  = [math]::Round($totalGB - $freeGB, 1);
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 1);
        $percentUsed = 100 - $percentFree;

        if ($percentFree -lt 10) {
            $dColor = "#EF4444";
            $dStatus = "KRITIK DOLULUK";
            $overallStatus = "CRITICAL";
            $overallStatusText = "KRITIK DISK ALANI";
            $overallStatusColor = "#EF4444";
        } elseif ($percentFree -lt 20) {
            $dColor = "#F59E0B";
            $dStatus = "UYARI";
            if ($overallStatus -ne "CRITICAL") {
                $overallStatus = "WARNING";
                $overallStatusText = "AZALAN DISK ALANI";
                $overallStatusColor = "#F59E0B";
            }
        } else {
            $dColor = "#10B981";
            $dStatus = "SAGLIKLI";
        }

        $diskCards += @"
        <div class="disk-box">
            <div class="disk-header">
                <div class="disk-name">Surucu $($d.DeviceID)</div>
                <div class="disk-badge" style="background: $dColor;">$dStatus</div>
            </div>
            <div class="disk-meta">
                <span>Kullanilan: <strong>$usedGB GB</strong></span>
                <span>Bos: <strong>$freeGB GB</strong> / $totalGB GB</span>
            </div>
            <div class="progress-bar-bg">
                <div class="progress-bar-fill" style="width: $percentUsed%; background: $dColor;"></div>
            </div>
            <div class="disk-footer">Doluluk Orani: %$percentUsed (Kalan: %$percentFree)</div>
        </div>
"@;
    }
} else {
    $diskCards = "<p>Disk bilgisi alinamadi.</p>";
}

# 5. En Cok Bellek Tuketen Ilk 5 Surec (Top 5 Processes)
Write-Host "[5/6] En cok kaynak tuketen ilk 5 surec listeleniyor..." -ForegroundColor Gray;
$topProcesses = Get-Process -ErrorAction SilentlyContinue | 
    Sort-Object WorkingSet64 -Descending | 
    Select-Object -First 5;

$procRows = "";
$rank = 1;
foreach ($p in $topProcesses) {
    $pMemMB = [math]::Round($p.WorkingSet64 / 1MB, 1);
    $procRows += @"
    <tr>
        <td><strong>#$rank</strong></td>
        <td><code>$($p.ProcessName)</code></td>
        <td>$($p.Id)</td>
        <td><strong>$pMemMB MB</strong></td>
    </tr>
"@;
    $rank++;
}

# 6. Kritik Windows Servisleri
Write-Host "[6/6] Kritik Windows servisleri denetleniyor..." -ForegroundColor Gray;
$criticalServices = @("LanmanServer", "LanmanWorkstation", "Spooler", "W32Time", "WinRM", "Dhcp", "Dnscache");
$srvGrid = "";

foreach ($sName in $criticalServices) {
    $srv = Get-Service -Name $sName -ErrorAction SilentlyContinue;
    if ($srv) {
        $status = $srv.Status;
        if ($status -eq "Running") {
            $sColor = "#10B981";
            $sBadge = "CALISIYOR";
            $sDot = "background: #10B981;";
        } else {
            $sColor = "#EF4444";
            $sBadge = "DURMUS!";
            $sDot = "background: #EF4444;";
            if ($overallStatus -ne "CRITICAL") {
                $overallStatus = "WARNING";
                $overallStatusText = "DURAN KRITIK SERVIS";
                $overallStatusColor = "#F59E0B";
            }
        }
        $dispName = $srv.DisplayName;
    } else {
        $sColor = "#64748B";
        $sBadge = "YUKLU DEGIL";
        $sDot = "background: #94A3B8;";
        $dispName = "Servis mevcut degil";
    }

    $srvGrid += @"
    <div class="srv-item">
        <div class="srv-left">
            <span class="srv-indicator" style="$sDot"></span>
            <div>
                <div class="srv-name">$sName</div>
                <div class="srv-desc">$dispName</div>
            </div>
        </div>
        <div class="srv-badge" style="color: $sColor; border: 1px solid $sColor;">$sBadge</div>
    </div>
"@;
}

# 7. Aktif Ag Karti ve IP Yapilandirmasi
$nic = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue | Select-Object -First 1;
$ipAddr = if ($nic.IPAddress) { $nic.IPAddress[0] } else { "N/A" };
$subnet = if ($nic.IPSubnet) { $nic.IPSubnet[0] } else { "N/A" };
$gateway = if ($nic.DefaultIPGateway) { $nic.DefaultIPGateway[0] } else { "N/A" };
$macAddr = if ($nic.MACAddress) { $nic.MACAddress } else { "N/A" };
$nicDesc = if ($nic.Description) { $nic.Description } else { "Ethernet Adapter" };

# 8. Modern Responsive HTML Dashboard Tasarimi
$htmlContent = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Health Dashboard - $serverName</title>
    <style>
        :root {
            --bg: #F8FAFC;
            --surface: #FFFFFF;
            --border: #E2E8F0;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --primary: #2563EB;
            --primary-soft: #EFF6FF;
            --success: #10B981;
            --warning: #F59E0B;
            --danger: #EF4444;
        }
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg);
            color: var(--text-main);
            margin: 0;
            padding: 24px 16px;
        }
        .dashboard-container {
            max-width: 1100px;
            margin: 0 auto;
        }
        .header-bar {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.04);
            margin-bottom: 20px;
        }
        .header-left h1 {
            margin: 0;
            font-size: 22px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .header-left .server-meta {
            margin-top: 6px;
            font-size: 13px;
            color: var(--text-muted);
        }
        .header-right {
            text-align: right;
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 6px;
        }
        .health-badge {
            display: inline-block;
            padding: 6px 14px;
            border-radius: 30px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
            color: white;
            text-transform: uppercase;
        }
        .author-tag {
            font-size: 12px;
            color: var(--primary);
            font-weight: 600;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 14px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 16px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.02);
        }
        .stat-card .label {
            font-size: 11px;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 6px;
        }
        .stat-card .value {
            font-size: 20px;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 4px;
        }
        .stat-card .subtext {
            font-size: 12px;
            color: var(--text-muted);
        }
        .main-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        .section-panel {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.02);
            margin-bottom: 20px;
        }
        .section-title {
            margin: 0 0 16px 0;
            font-size: 16px;
            font-weight: 700;
            color: var(--text-main);
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border);
            padding-bottom: 10px;
        }
        .disk-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 14px;
        }
        .disk-box {
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 14px;
        }
        .disk-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }
        .disk-name {
            font-size: 15px;
            font-weight: 700;
        }
        .disk-badge {
            font-size: 10px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 12px;
            color: white;
        }
        .disk-meta {
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: var(--text-muted);
            margin-bottom: 8px;
        }
        .progress-bar-bg {
            background: #E2E8F0;
            height: 10px;
            border-radius: 5px;
            overflow: hidden;
            margin-bottom: 6px;
        }
        .progress-bar-fill {
            height: 100%;
            border-radius: 5px;
            transition: width 0.4s ease;
        }
        .disk-footer {
            font-size: 11px;
            color: var(--text-muted);
            text-align: right;
        }
        .srv-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 8px;
        }
        .srv-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 12px;
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: 8px;
        }
        .srv-left {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .srv-indicator {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
        }
        .srv-name {
            font-size: 13px;
            font-weight: 700;
        }
        .srv-desc {
            font-size: 11px;
            color: var(--text-muted);
        }
        .srv-badge {
            font-size: 10px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 4px;
            background: white;
        }
        table.proc-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        table.proc-table th, table.proc-table td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        table.proc-table th {
            background: var(--bg);
            font-size: 11px;
            color: var(--text-muted);
            text-transform: uppercase;
        }
        .net-info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            font-size: 13px;
        }
        .net-item {
            background: var(--bg);
            padding: 10px 12px;
            border-radius: 6px;
            border: 1px solid var(--border);
        }
        .net-item span {
            display: block;
            font-size: 11px;
            color: var(--text-muted);
            margin-bottom: 2px;
        }
        .footer-bar {
            text-align: center;
            font-size: 12px;
            color: var(--text-muted);
            padding: 20px 0;
            border-top: 1px solid var(--border);
            margin-top: 20px;
        }
        @media (max-width: 860px) {
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
            .main-layout { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <div class="header-bar">
            <div class="header-left">
                <h1>Windows Sunucu Durum Paneli</h1>
                <div class="server-meta">
                    <strong>Sunucu:</strong> $serverName &nbsp;|&nbsp; 
                    <strong>OS:</strong> $osName ($osArch) &nbsp;|&nbsp; 
                    <strong>Rapor Tarihi:</strong> $reportTime
                </div>
            </div>
            <div class="header-right">
                <span class="health-badge" style="background: $overallStatusColor;">$overallStatusText</span>
                <span class="author-tag">Hazirlayan: Samet Cakmak</span>
            </div>
        </div>

        <!-- 4 Top KPI Metric Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="label">CPU Yuku</div>
                <div class="value">%$cpuLoad</div>
                <div class="subtext">$cpuCores C / $cpuThreads T ($cpuName)</div>
            </div>
            <div class="stat-card">
                <div class="label">RAM Kullanimi</div>
                <div class="value">%$percentRAMUsed</div>
                <div class="subtext">$usedRAM GB kullanildi / $totalRAM GB toplam</div>
            </div>
            <div class="stat-card">
                <div class="label">Sistem Uptime</div>
                <div class="value" style="font-size: 16px; margin-top: 4px;">$uptimeStr</div>
                <div class="subtext">Son acilis: $lastBootStr</div>
            </div>
            <div class="stat-card">
                <div class="label">Ag Baglantisi</div>
                <div class="value" style="font-size: 16px; margin-top: 4px;">$ipAddr</div>
                <div class="subtext">Ag Gecidi: $gateway</div>
            </div>
        </div>

        <!-- Main Layout (Disks & Network left, Services & Processes right) -->
        <div class="main-layout">
            <!-- Left Column -->
            <div>
                <!-- Storage Section -->
                <div class="section-panel">
                    <div class="section-title">
                        <span>Disk Depolama Durumu</span>
                        <small style="font-size: 12px; color: var(--text-muted); font-weight: normal;">$($disks.Count) Surucu</small>
                    </div>
                    <div class="disk-grid">
                        $diskCards
                    </div>
                </div>

                <!-- Network Details -->
                <div class="section-panel">
                    <div class="section-title">
                        <span>Ag Yapilandirmasi & IP Bilgileri</span>
                        <small style="font-size: 12px; color: var(--text-muted); font-weight: normal;">$nicDesc</small>
                    </div>
                    <div class="net-info-grid">
                        <div class="net-item">
                            <span>IPv4 Adresi</span>
                            <strong>$ipAddr</strong>
                        </div>
                        <div class="net-item">
                            <span>Alt Ag Maskesi (Subnet)</span>
                            <strong>$subnet</strong>
                        </div>
                        <div class="net-item">
                            <span>Varsayilan Ag Gecidi (Gateway)</span>
                            <strong>$gateway</strong>
                        </div>
                        <div class="net-item">
                            <span>Fiziksel Adres (MAC)</span>
                            <strong>$macAddr</strong>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right Column -->
            <div>
                <!-- Critical Services -->
                <div class="section-panel">
                    <div class="section-title">
                        <span>Kritik Servisler</span>
                        <small style="font-size: 12px; color: var(--text-muted); font-weight: normal;">$($criticalServices.Count) Servis</small>
                    </div>
                    <div class="srv-grid">
                        $srvGrid
                    </div>
                </div>

                <!-- Top 5 Processes -->
                <div class="section-panel">
                    <div class="section-title">
                        <span>En Cok Bellek Tuketimi (Top 5)</span>
                    </div>
                    <table class="proc-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Surec</th>
                                <th>PID</th>
                                <th>RAM</th>
                            </tr>
                        </thead>
                        <tbody>
                            $procRows
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer-bar">
            <strong>PowerShell Sysadmin Toolkit v2.0</strong> &nbsp;|&nbsp; 
            Gelistirici: <strong>Samet Cakmak</strong> &nbsp;|&nbsp; 
            Otomasyon Raporu
        </div>
    </div>
</body>
</html>
"@;

$htmlContent | Out-File -FilePath $OutputHtmlPath -Encoding UTF8;
Write-Host "`n[OK] Gelismis dashboard basariyla olusturuldu: $OutputHtmlPath" -ForegroundColor Green;
Write-Host "     (Tarayicinizda acip modern paneli inceleyebilirsiniz.)`n" -ForegroundColor DarkGray;

