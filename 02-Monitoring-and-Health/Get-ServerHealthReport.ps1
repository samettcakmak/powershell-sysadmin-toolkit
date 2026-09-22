<#
.SYNOPSIS
    Kurumsal Windows Sunucu Saglik Paneli (Sifir Scroll, Responsive & Gizlilik Korumali).
.DESCRIPTION
    Sunucunun CPU, RAM, Disk doluluklarini havali gorsel gostergelerle (radial conic gauges),
    sistem calisma suresini (Uptime), ag kartlarini, en cok kaynak tuketen surecleri
    ve kritik servisleri tek ekranda kaydirma cubugu olmadan toplayan kurumsal HTML dashboard.
    LinkedIn / GitHub ekran goruntuleri icin tek tikla IP ve sunucu adini gizleme (privacy mode) icerir.
.PARAMETER OutputHtmlPath
    Olusturulacak HTML dashboard dosyasinin yolu.
.EXAMPLE
    .\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
.NOTES
    Yazar : Samet Cakmak
    Surum : 3.1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputHtmlPath = ".\ServerHealthReport.html"
)

Write-Host "==========================================================" -ForegroundColor Cyan;
Write-Host "  WINDOWS SUNUCU SAGLIK DASHBOARD V3.1 (ZERO-SCROLL)" -ForegroundColor Cyan;
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Cyan;
Write-Host "==========================================================" -ForegroundColor Cyan;

$serverName = $env:COMPUTERNAME;
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss";
$overallStatus = "HEALTHY";
$overallStatusText = "SISTEM SAGLIKLI";
$overallStatusColor = "#10B981";

# 1. Isletim Sistemi ve Uptime
Write-Host "[1/6] Sistem mimarisi ve calisma suresi aliniyor..." -ForegroundColor Gray;
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue;
$osName = if ($os.Caption) { $os.Caption.Trim() } else { "Windows Server" };
$osArch = if ($os.OSArchitecture) { $os.OSArchitecture } else { "64-bit" };

$uptimeStr = "N/A";
$lastBootStr = "N/A";
if ($os.LastBootUpTime) {
    $uptime = (Get-Date) - $os.LastBootUpTime;
    $uptimeStr = "$($uptime.Days)g $($uptime.Hours)s $($uptime.Minutes)d";
    $lastBootStr = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm");
}

# 2. CPU / Islemci Bilgisi ve Yuk
Write-Host "[2/6] Islemci yuku ve cekirdek bilgisi okunuyor..." -ForegroundColor Gray;
$cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1;
$cpuName = if ($cpu.Name) { $cpu.Name.Trim() } else { "Intel/AMD Processor" };
$cpuCores = if ($cpu.NumberOfCores) { $cpu.NumberOfCores } else { 2 };
$cpuThreads = if ($cpu.NumberOfLogicalProcessors) { $cpu.NumberOfLogicalProcessors } else { 4 };
$cpuLoad = if ($null -ne $cpu.LoadPercentage) { $cpu.LoadPercentage } else { 0 };

$cpuGaugeColor = if ($cpuLoad -gt 85) { "#EF4444" } elseif ($cpuLoad -gt 65) { "#F59E0B" } else { "#3B82F6" };

# 3. RAM (Bellek) Durumu
Write-Host "[3/6] RAM havuzu tahlil ediliyor..." -ForegroundColor Gray;
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1);
$freeRAM  = [math]::Round($os.FreePhysicalMemory / 1MB, 1);
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 1);
$percentRAMUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1);

$ramGaugeColor = "#10B981";
if ($percentRAMUsed -gt 90) {
    $ramGaugeColor = "#EF4444";
    $overallStatus = "CRITICAL";
    $overallStatusText = "KRITIK BELLEK";
    $overallStatusColor = "#EF4444";
} elseif ($percentRAMUsed -gt 80) {
    $ramGaugeColor = "#F59E0B";
    if ($overallStatus -ne "CRITICAL") {
        $overallStatus = "WARNING";
        $overallStatusText = "YUKSEK BELLEK";
        $overallStatusColor = "#F59E0B";
    }
}

# 4. Disk Depolama Alanlari
Write-Host "[4/6] Disk suruculeri analiz ediliyor..." -ForegroundColor Gray;
$disks = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue);
$diskCount = $disks.Count;

$diskCards = "";
if ($disks -and $diskCount -gt 0) {
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 1);
        $freeGB  = [math]::Round($d.FreeSpace / 1GB, 1);
        $usedGB  = [math]::Round($totalGB - $freeGB, 1);
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 1);
        $percentUsed = 100 - $percentFree;

        if ($percentFree -lt 10) {
            $dColor = "#EF4444";
            $dStatus = "KRITIK";
            $overallStatus = "CRITICAL";
            $overallStatusText = "KRITIK DISK ALANI";
            $overallStatusColor = "#EF4444";
        } elseif ($percentFree -lt 20) {
            $dColor = "#F59E0B";
            $dStatus = "AZALIYOR";
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
        <div class="disk-card">
            <div class="disk-top">
                <div class="disk-letter">Surucu $($d.DeviceID)</div>
                <div class="badge" style="background: $dColor;">$dStatus</div>
            </div>
            <div class="progress-container">
                <div class="progress-fill" style="width: $percentUsed%; background: $dColor;"></div>
            </div>
            <div class="disk-bottom">
                <span>Kullanilan: <strong>$usedGB GB</strong> (%$percentUsed)</span>
                <span>Bos: <strong>$freeGB GB</strong> / $totalGB GB</span>
            </div>
        </div>
"@;
    }
} else {
    $diskCards = "<div class='no-data'>Disk bilgisi alinamadi.</div>";
}

# 5. En Cok Bellek Tuketen Ilk 5 Surec
Write-Host "[5/6] En cok kaynak tuketen surecler siralaniyor..." -ForegroundColor Gray;
$topProcesses = Get-Process -ErrorAction SilentlyContinue | 
    Sort-Object WorkingSet64 -Descending | 
    Select-Object -First 5;

$procRows = "";
$pIdx = 1;
foreach ($p in $topProcesses) {
    $pMemMB = [math]::Round($p.WorkingSet64 / 1MB, 1);
    $procRows += @"
    <tr>
        <td class="proc-rank">#$pIdx</td>
        <td class="proc-name"><code>$($p.ProcessName)</code></td>
        <td class="proc-pid">$($p.Id)</td>
        <td class="proc-ram"><strong>$pMemMB MB</strong></td>
    </tr>
"@;
    $pIdx++;
}

# 6. Kritik Windows Servisleri
Write-Host "[6/6] Kritik servisler taraniyor..." -ForegroundColor Gray;
$criticalServices = @("LanmanServer", "LanmanWorkstation", "Spooler", "W32Time", "WinRM", "Dhcp", "Dnscache");
$srvRows = "";

foreach ($sName in $criticalServices) {
    $srv = Get-Service -Name $sName -ErrorAction SilentlyContinue;
    if ($srv) {
        $status = $srv.Status;
        if ($status -eq "Running") {
            $sColor = "#10B981";
            $sBadge = "CALISIYOR";
            $sPulse = "background: #10B981;";
        } else {
            $sColor = "#EF4444";
            $sBadge = "DURMUS!";
            $sPulse = "background: #EF4444;";
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
        $sPulse = "background: #64748B;";
        $dispName = "Servis kurulu degil";
    }

    $srvRows += @"
    <div class="srv-row">
        <div class="srv-info">
            <span class="pulse-dot" style="$sPulse"></span>
            <div class="srv-text-group">
                <span class="srv-title">$sName</span>
                <span class="srv-sub">$dispName</span>
            </div>
        </div>
        <div class="srv-status-chip" style="color: $sColor; border: 1px solid $sColor;">$sBadge</div>
    </div>
"@;
}

# 7. Aktif Ag Karti ve IP Yapilandirmasi
$nic = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue | Select-Object -First 1;
$ipAddr  = if ($nic.IPAddress) { $nic.IPAddress[0] } else { "N/A" };
$subnet  = if ($nic.IPSubnet) { $nic.IPSubnet[0] } else { "N/A" };
$gateway = if ($nic.DefaultIPGateway) { $nic.DefaultIPGateway[0] } else { "N/A" };
$macAddr = if ($nic.MACAddress) { $nic.MACAddress } else { "N/A" };
$nicDesc = if ($nic.Description) { $nic.Description } else { "Ethernet Bagdastiricisi" };

# 8. Modern Single-Screen SOC Dashboard HTML Sablonu
$htmlContent = @"
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Health Dashboard - $serverName</title>
    <style>
        :root {
            --bg-base: #0B0F19;
            --surface: #111827;
            --surface-hover: #1F2937;
            --border: rgba(255, 255, 255, 0.08);
            --text-white: #F8FAFC;
            --text-dim: #94A3B8;
            --primary: #3B82F6;
            --success: #10B981;
            --warning: #F59E0B;
            --danger: #EF4444;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-base);
            color: var(--text-white);
            padding: 14px 18px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
        .container {
            max-width: 1380px;
            margin: 0 auto;
            width: 100%;
        }
        /* Top Navigation & Status Bar */
        .top-bar {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 10px 18px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }
        .title-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .pulse-live {
            width: 10px; height: 10px; border-radius: 50%;
            background: $overallStatusColor;
            box-shadow: 0 0 10px $overallStatusColor;
            animation: pulse-live 1.8s infinite;
        }
        @keyframes pulse-live {
            0% { transform: scale(0.95); opacity: 0.8; }
            50% { transform: scale(1.15); opacity: 1; }
            100% { transform: scale(0.95); opacity: 0.8; }
        }
        .title-text h1 {
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 0.5px;
            color: var(--text-white);
        }
        .title-text .sub {
            font-size: 10.5px;
            color: var(--text-dim);
            margin-top: 2px;
        }
        .actions-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .privacy-btn {
            background: rgba(59, 130, 246, 0.15);
            border: 1px solid rgba(59, 130, 246, 0.4);
            color: #60A5FA;
            font-size: 11px;
            font-weight: 700;
            padding: 5px 12px;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .privacy-btn:hover {
            background: rgba(59, 130, 246, 0.3);
            border-color: #60A5FA;
        }
        .privacy-btn.active {
            background: rgba(239, 68, 68, 0.2);
            border-color: #EF4444;
            color: #FCA5A5;
        }
        .badge-status {
            padding: 5px 12px;
            border-radius: 6px;
            font-size: 10.5px;
            font-weight: 800;
            letter-spacing: 0.5px;
            color: white;
            text-transform: uppercase;
        }

        /* 4 Top KPI Cards */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            margin-bottom: 12px;
        }
        .kpi-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 10px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        }
        .kpi-info .kpi-label {
            font-size: 10px;
            font-weight: 700;
            color: var(--text-dim);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 2px;
        }
        .kpi-info .kpi-val {
            font-size: 18px;
            font-weight: 800;
            color: var(--text-white);
        }
        .kpi-info .kpi-sub {
            font-size: 10px;
            color: var(--text-dim);
            margin-top: 2px;
        }
        .gauge-conic {
            width: 52px; height: 52px; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            position: relative;
            flex-shrink: 0;
        }
        .gauge-inner {
            width: 40px; height: 40px; border-radius: 50%;
            background: var(--surface);
            display: flex; align-items: center; justify-content: center;
            font-size: 11px; font-weight: 800;
            color: var(--text-white);
        }

        /* 3-Column Core Grid */
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 10px;
        }
        .panel {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px 14px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.2);
            display: flex;
            flex-direction: column;
        }
        .panel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border);
            padding-bottom: 6px;
            margin-bottom: 8px;
        }
        .panel-title {
            font-size: 11.5px;
            font-weight: 700;
            color: var(--text-white);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .panel-sub {
            font-size: 10px;
            color: var(--text-dim);
        }

        /* Storage Bars */
        .disk-card {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border);
            border-radius: 6px;
            padding: 8px 10px;
            margin-bottom: 6px;
        }
        .disk-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 11.5px;
            font-weight: 700;
            margin-bottom: 4px;
        }
        .progress-container {
            background: rgba(255, 255, 255, 0.08);
            height: 6px;
            border-radius: 3px;
            overflow: hidden;
            margin-bottom: 4px;
        }
        .progress-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.4s ease;
        }
        .disk-bottom {
            display: flex;
            justify-content: space-between;
            font-size: 10px;
            color: var(--text-dim);
        }
        .badge {
            font-size: 8.5px;
            padding: 2px 6px;
            border-radius: 8px;
            color: white;
            font-weight: 700;
        }

        /* Network Info List */
        .net-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
            margin-top: 2px;
        }
        .net-table td {
            padding: 4px 2px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.04);
        }
        .net-table .label-col {
            color: var(--text-dim);
            width: 38%;
        }
        .net-table .val-col {
            font-weight: 600;
            color: var(--text-white);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        /* ZERO-SCROLL Compact Services List */
        .srv-list {
            display: flex;
            flex-direction: column;
            gap: 4px;
            overflow: visible;
        }
        .srv-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 4px 8px;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border);
            border-radius: 5px;
        }
        .srv-info {
            display: flex;
            align-items: center;
            gap: 7px;
            min-width: 0;
        }
        .pulse-dot {
            width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0;
        }
        .srv-text-group {
            display: flex;
            align-items: baseline;
            gap: 6px;
            min-width: 0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .srv-title {
            font-size: 11px;
            font-weight: 700;
            color: var(--text-white);
        }
        .srv-sub {
            font-size: 9px;
            color: var(--text-dim);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 150px;
        }
        .srv-status-chip {
            font-size: 8.5px;
            font-weight: 700;
            padding: 1px 5px;
            border-radius: 3px;
            flex-shrink: 0;
            margin-left: 6px;
        }

        /* Processes Table */
        table.proc-tbl {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
        }
        table.proc-tbl th, table.proc-tbl td {
            padding: 5px 6px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        table.proc-tbl th {
            font-size: 9px;
            text-transform: uppercase;
            color: var(--text-dim);
            font-weight: 700;
        }
        .proc-rank { color: var(--primary); font-weight: 800; width: 20px; }
        .proc-name code { background: rgba(255,255,255,0.05); padding: 1px 4px; border-radius: 3px; color: #93C5FD; font-size: 10.5px; }
        .proc-pid { color: var(--text-dim); font-size: 10px; }
        .proc-ram { color: #34D399; font-weight: 700; text-align: right; }

        /* Privacy Masking Styles */
        .maskable {
            transition: filter 0.2s ease, opacity 0.2s ease;
            display: inline-block;
        }
        .is-blurred {
            filter: blur(5px) !important;
            user-select: none !important;
            opacity: 0.4 !important;
        }
        .eye-toggle-btn {
            background: none;
            border: none;
            color: var(--text-dim);
            cursor: pointer;
            font-size: 11px;
            padding: 0 4px;
            opacity: 0.6;
            transition: opacity 0.2s;
        }
        .eye-toggle-btn:hover {
            opacity: 1;
            color: var(--primary);
        }

        /* Footer */
        .bottom-bar {
            text-align: center;
            font-size: 10.5px;
            color: var(--text-dim);
            margin-top: 10px;
            padding-top: 6px;
            border-top: 1px solid var(--border);
        }

        @media (max-width: 1024px) {
            .kpi-grid { grid-template-columns: repeat(2, 1fr); }
            .main-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Top Bar -->
        <div class="top-bar">
            <div class="title-group">
                <span class="pulse-live"></span>
                <div class="title-text">
                    <h1>Sistem Durum Paneli <span class="maskable" id="field-srvname" style="color: #60A5FA;">[$serverName]</span></h1>
                    <div class="sub">$osName ($osArch) &bull; Rapor: $reportTime</div>
                </div>
            </div>
            <div class="actions-group">
                <button class="privacy-btn" id="masterPrivacyBtn" onclick="toggleMasterPrivacy()">
                    &#128274; Gizlilik Modu (Screenshot)
                </button>
                <div class="badge-status" style="background: $overallStatusColor;">$overallStatusText</div>
            </div>
        </div>

        <!-- 4 KPI Cards with Gauges -->
        <div class="kpi-grid">
            <!-- CPU Card -->
            <div class="kpi-card">
                <div class="kpi-info">
                    <div class="kpi-label">CPU Yuku</div>
                    <div class="kpi-val">%$cpuLoad</div>
                    <div class="kpi-sub">$cpuCores Cekirdek / $cpuThreads Izlek</div>
                </div>
                <div class="gauge-conic" style="background: conic-gradient($cpuGaugeColor calc($cpuLoad * 1%), rgba(255,255,255,0.06) 0);">
                    <div class="gauge-inner">%$cpuLoad</div>
                </div>
            </div>

            <!-- RAM Card -->
            <div class="kpi-card">
                <div class="kpi-info">
                    <div class="kpi-label">RAM Kullanimi</div>
                    <div class="kpi-val">%$percentRAMUsed</div>
                    <div class="kpi-sub">$usedRAM GB / $totalRAM GB</div>
                </div>
                <div class="gauge-conic" style="background: conic-gradient($ramGaugeColor calc($percentRAMUsed * 1%), rgba(255,255,255,0.06) 0);">
                    <div class="gauge-inner">%$percentRAMUsed</div>
                </div>
            </div>

            <!-- Uptime Card -->
            <div class="kpi-card">
                <div class="kpi-info">
                    <div class="kpi-label">Sistem Uptime</div>
                    <div class="kpi-val" style="font-size: 16px; margin-top: 2px;">$uptimeStr</div>
                    <div class="kpi-sub">Acilis: $lastBootStr</div>
                </div>
                <div class="gauge-conic" style="background: conic-gradient(#10B981 100%, rgba(255,255,255,0.06) 0);">
                    <div class="gauge-inner" style="font-size: 15px; color: #10B981; font-weight: 800;">UP</div>
                </div>
            </div>

            <!-- Network Primary Card -->
            <div class="kpi-card">
                <div class="kpi-info">
                    <div class="kpi-label">Birincil IPv4</div>
                    <div class="kpi-val" style="font-size: 15px; margin-top: 2px;">
                        <span class="maskable" id="field-kpi-ip">$ipAddr</span>
                        <button class="eye-toggle-btn" onclick="toggleSingle('field-kpi-ip', this)" title="Gizle/Goster">&#128065;</button>
                    </div>
                    <div class="kpi-sub">
                        Gecit: <span class="maskable" id="field-kpi-gw">$gateway</span>
                    </div>
                </div>
                <div class="gauge-conic" style="background: conic-gradient(#3B82F6 100%, rgba(255,255,255,0.06) 0);">
                    <div class="gauge-inner" style="font-size: 16px;">&#127760;</div>
                </div>
            </div>
        </div>

        <!-- 3-Column Main Grid -->
        <div class="main-grid">
            <!-- Col 1: Storage & Network -->
            <div class="panel">
                <div class="panel-header">
                    <span class="panel-title">&#128190; Disk Depolama ($diskCount Surucu)</span>
                </div>
                <div style="margin-bottom: 10px;">
                    $diskCards
                </div>

                <div class="panel-header" style="margin-top: 2px;">
                    <span class="panel-title">&#127760; Ag Yapilandirmasi</span>
                    <button class="eye-toggle-btn" onclick="toggleNetFields()" title="Ag Bilgilerini Gizle">&#128274;</button>
                </div>
                <table class="net-table">
                    <tr>
                        <td class="label-col">IPv4 Adresi:</td>
                        <td class="val-col">
                            <span class="maskable" id="net-ip">$ipAddr</span>
                            <button class="eye-toggle-btn" onclick="toggleSingle('net-ip', this)">&#128065;</button>
                        </td>
                    </tr>
                    <tr>
                        <td class="label-col">Alt Ag Maskesi:</td>
                        <td class="val-col">
                            <span class="maskable" id="net-sub">$subnet</span>
                            <button class="eye-toggle-btn" onclick="toggleSingle('net-sub', this)">&#128065;</button>
                        </td>
                    </tr>
                    <tr>
                        <td class="label-col">Ag Gecidi (Gateway):</td>
                        <td class="val-col">
                            <span class="maskable" id="net-gw">$gateway</span>
                            <button class="eye-toggle-btn" onclick="toggleSingle('net-gw', this)">&#128065;</button>
                        </td>
                    </tr>
                    <tr>
                        <td class="label-col">Fiziksel MAC:</td>
                        <td class="val-col">
                            <span class="maskable" id="net-mac">$macAddr</span>
                            <button class="eye-toggle-btn" onclick="toggleSingle('net-mac', this)">&#128065;</button>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- Col 2: Services (ZERO-SCROLL FIXED) -->
            <div class="panel">
                <div class="panel-header">
                    <span class="panel-title">&#9881; Kritik Servisler ($($criticalServices.Count))</span>
                    <span class="panel-sub">Gercek Zamanli Durum</span>
                </div>
                <div class="srv-list">
                    $srvRows
                </div>
            </div>

            <!-- Col 3: Processes -->
            <div class="panel">
                <div class="panel-header">
                    <span class="panel-title">&#128293; En Cok Bellek Tuketen Ilk 5</span>
                    <span class="panel-sub">RAM Siralamasi</span>
                </div>
                <table class="proc-tbl">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Surec Adi</th>
                            <th>PID</th>
                            <th style="text-align: right;">RAM</th>
                        </tr>
                    </thead>
                    <tbody>
                        $procRows
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Footer -->
        <div class="bottom-bar">
            PowerShell Sysadmin Toolkit v3.1 &nbsp;&bull;&nbsp; 
            Hazirlayan: <strong>Samet Cakmak</strong> &nbsp;&bull;&nbsp; 
            Sifir Kaydirma & Ekran Goruntusu Modu Destekli
        </div>
    </div>

    <!-- Client-side Privacy & Masking Script -->
    <script>
        let isMasterMasked = false;

        function toggleMasterPrivacy() {
            isMasterMasked = !isMasterMasked;
            const btn = document.getElementById('masterPrivacyBtn');
            const sensitiveEls = document.querySelectorAll('.maskable');
            
            sensitiveEls.forEach(el => {
                if (isMasterMasked) {
                    el.classList.add('is-blurred');
                } else {
                    el.classList.remove('is-blurred');
                }
            });

            if (isMasterMasked) {
                btn.innerHTML = '&#128275; Tumunu Goster';
                btn.classList.add('active');
            } else {
                btn.innerHTML = '&#128274; Gizlilik Modu (Screenshot)';
                btn.classList.remove('active');
            }
        }

        function toggleSingle(id, btn) {
            const el = document.getElementById(id);
            if (el) {
                el.classList.toggle('is-blurred');
                btn.innerHTML = el.classList.contains('is-blurred') ? '&#128274;' : '&#128065;';
            }
        }

        function toggleNetFields() {
            ['net-ip', 'net-sub', 'net-gw', 'net-mac'].forEach(id => {
                const el = document.getElementById(id);
                if (el) el.classList.toggle('is-blurred');
            });
        }
    </script>
</body>
</html>
"@;

$htmlContent | Out-File -FilePath $OutputHtmlPath -Encoding UTF8;
Write-Host "`n[OK] V3.1 Dashboard basariyla olusturuldu: $OutputHtmlPath" -ForegroundColor Green;
Write-Host "     (Tarayicinizda acip scroolsun temiz gorunumu inceleyebilirsiniz.)`n" -ForegroundColor DarkGray;

