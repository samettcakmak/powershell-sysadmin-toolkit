<#
.SYNOPSIS
    Yerel Yonetici (Local Admin) Guvenlik Denetim ve Temizleme (Remediation) Betigi.
.DESCRIPTION
    Bilgisayardaki 'Administrators' grubunu denetler, yetkisiz veya supheli hesaplari
    tespit eder ve yoneticiye numaralandirilmis interaktif bir menu ile
    bu hesaplari tek tek ya da topluca gruptan kaldirma imkani sunar.
.EXAMPLE
    .\Audit-LocalAdminAccounts.ps1
.NOTES
    Yazar : Samet Cakmak
    Surum : 2.0.0 (Interactive Remediation Edition)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$AuthorizedAdmins = @("Administrator", "Domain Admins", "Enterprise Admins")
)

Clear-Host
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  YEREL YONETICI (LOCAL ADMIN) DENETIM & TEMIZLEME ARACI " -ForegroundColor Yellow
Write-Host "  Hazirlayan: Samet Cakmak | Surum 2.0" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$computerName = $env:COMPUTERNAME
$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$isDC = ($cs.DomainRole -eq 4 -or $cs.DomainRole -eq 5)
$roleName = if ($isDC) { "Domain Controller (DC)" } else { "Istemci / Uye Sunucu" }

Write-Host "[-] Hedef Cihaz : $computerName" -ForegroundColor Cyan
Write-Host "[-] Cihaz Rolu  : $roleName" -ForegroundColor Cyan

# Yoneticileri Toplama
$admins = @()
if (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue -and -not $isDC) {
    $locMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    foreach ($m in $locMembers) {
        $admins += [PSCustomObject]@{
            Name        = $m.Name
            ObjectClass = $m.ObjectClass
            RawObject   = $m
        }
    }
} else {
    $rawNet = net localgroup Administrators 2>$null
    $capturing = $false
    foreach ($line in $rawNet) {
        $trimLine = $line.Trim()
        if ($trimLine -like "---*") { $capturing = $true; continue }
        if ($trimLine -like "*command completed*" -or $trimLine -like "*komut basariyla*") { $capturing = $false; break }
        if ($capturing -and $trimLine.Length -gt 0) {
            $admins += [PSCustomObject]@{
                Name        = $trimLine
                ObjectClass = "User/Group"
                RawObject   = $trimLine
            }
        }
    }
}

if (-not $admins -or $admins.Count -eq 0) {
    Write-Host "[!] 'Administrators' grubu okunamadi veya grup bos." -ForegroundColor Red
    exit
}

Write-Host "[-] Toplam Yonetici Sayisi: $($admins.Count)`n" -ForegroundColor Cyan

$riskyAccounts = @()

foreach ($member in $admins) {
    $name = $member.Name
    $class = $member.ObjectClass
    $isAuthorized = $false

    foreach ($auth in $AuthorizedAdmins) {
        if ($name -like "*$auth*") {
            $isAuthorized = $true
            break
        }
    }

    if ($isAuthorized) {
        Write-Host "  [OK - Yetkili] $name ($class)" -ForegroundColor Green
    } else {
        Write-Host "  [RISK - INCELEME GEREKIR] $name ($class)" -ForegroundColor Red
        $riskyAccounts += $member
    }
}

Write-Host "`n==========================================================" -ForegroundColor Yellow

if ($riskyAccounts.Count -eq 0) {
    Write-Host "  [OK] GUVENLI: Supheli veya yetkisiz yerel yonetici tespit edilmedi." -ForegroundColor Green
    Write-Host "==========================================================`n" -ForegroundColor Yellow
    exit
}

Write-Host "  [!] UYARI: $($riskyAccounts.Count) adet yetkisiz/riskli hesap tespit edildi!" -ForegroundColor Red
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host ""

# Interaktif Kaldirma Menusu
Write-Host "--- ISLEM MENUSU ---" -ForegroundColor Cyan
for ($i = 0; $i -lt $riskyAccounts.Count; $i++) {
    Write-Host "  [$($i + 1)] $($riskyAccounts[$i].Name) hesabini Administrators grubundan cikar" -ForegroundColor White
}
if ($riskyAccounts.Count -gt 1) {
    Write-Host "  [A] Tum riskli hesaplari gruptan cikar" -ForegroundColor Magenta
}
Write-Host "  [0] Cikis (Hicbir islem yapma)" -ForegroundColor Gray
Write-Host ""

$secim = Read-Host "Lutfen yapmak istediginiz islemi secin"

if ($secim -eq "0" -or [string]::IsNullOrWhiteSpace($secim)) {
    Write-Host "`n[-] Islem iptal edildi. Hicbir degisiklik yapilmadi.`n" -ForegroundColor Yellow
    exit
}

function Remove-AdminMember {
    param ($targetAccount)
    
    $accName = $targetAccount.Name
    Write-Host "`n[?] '$accName' hesabini 'Administrators' grubundan cikarmak istediginize emin misiniz? (E/H): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    if ($confirm -notmatch '^[eEyY]') {
        Write-Host "[-] Islem kullanici tarafindan atlandi: $accName" -ForegroundColor Gray
        return
    }

    try {
        if (Get-Command Remove-LocalGroupMember -ErrorAction SilentlyContinue) {
            Remove-LocalGroupMember -Group "Administrators" -Member $accName -ErrorAction Stop
            Write-Host "[+] BASARILI: '$accName' basariyla Administrators grubundan kaldirildi!" -ForegroundColor Green
        } else {
            # Yedek yontem
            $cleanName = if ($accName -match '\\') { $accName.Split('\')[-1] } else { $accName }
            net localgroup Administrators "`"$cleanName`"" /delete
            Write-Host "[+] BASARILI: '$cleanName' net komutu ile gruptan kaldirildi!" -ForegroundColor Green
        }
    } catch {
        Write-Host "[!] HATA: '$accName' kaldirilamadi! Hata: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[i] Ipucu: Bu islemi gerceklestirmek icin PowerShell'i 'Yonetici Olarak Calistir' ile acmalisiniz." -ForegroundColor Yellow
    }
}

if ($secim -match '^[aA]$') {
    foreach ($acc in $riskyAccounts) {
        Remove-AdminMember -targetAccount $acc
    }
} elseif ($secim -match '^\d+$') {
    $index = [int]$secim - 1
    if ($index -ge 0 -and $index -lt $riskyAccounts.Count) {
        Remove-AdminMember -targetAccount $riskyAccounts[$index]
    } else {
        Write-Host "[!] Gecersiz secim numarasi girildi." -ForegroundColor Red
    }
} else {
    Write-Host "[!] Gecersiz girdi." -ForegroundColor Red
}

Write-Host "`n[+] Islem tamamlandi.`n" -ForegroundColor Cyan

