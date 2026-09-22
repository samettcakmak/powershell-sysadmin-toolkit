<#
.SYNOPSIS
    Yerel Yonetici (Local Administrators) Guvenlik Denetim Betigi.
.DESCRIPTION
    Bilgisayardaki 'Administrators' grubuna dahil olan kullanici ve gruplari listeler.
    Standart kullanicilarin veya yetkisiz hesaplarin local admin olup olmadigini
    denetler ve guvenlik riski olusturan hesaplari raporlar.
.EXAMPLE
    .\Audit-LocalAdminAccounts.ps1
.NOTES
    Yazar : Samet Cakmak
    Surum : 1.1.0 (ASCII Edition)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$AuthorizedAdmins = @("Administrator", "Domain Admins")
)

Write-Host "==========================================================" -ForegroundColor Yellow;
Write-Host "  YEREL YONETICI (LOCAL ADMIN) GUVENLIK AUDIT BETIGI" -ForegroundColor Yellow;
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Yellow;
Write-Host "==========================================================" -ForegroundColor Yellow;

$admins = @(Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue);

if (-not $admins -or $admins.Count -eq 0) {
    Write-Host "[!] 'Administrators' grubu okunamadi veya bos." -ForegroundColor Red;
    exit;
}

Write-Host "[-] Denetlenen Cihaz: $env:COMPUTERNAME" -ForegroundColor Cyan;
Write-Host "[-] Toplam Local Admin Sayisi: $($admins.Count)`n" -ForegroundColor Cyan;

$flaggedCount = 0;

foreach ($member in $admins) {
    $name = $member.Name;
    $class = $member.ObjectClass;
    $isAuthorized = $false;

    foreach ($auth in $AuthorizedAdmins) {
        if ($name -like "*$auth*") {
            $isAuthorized = $true;
            break;
        }
    }

    if ($isAuthorized) {
        Write-Host "  [OK - Yetkili] $name ($class)" -ForegroundColor Green;
    } else {
        Write-Host "  [RISK - INCELEME GEREKIR] $name ($class)" -ForegroundColor Red;
        $flaggedCount++;
    }
}

Write-Host "`n==========================================================" -ForegroundColor Yellow;
if ($flaggedCount -gt 0) {
    Write-Host "  [!] UYARI: $flaggedCount adet yetkisiz veya supheli Local Admin tespit edildi!" -ForegroundColor Red;
    Write-Host "  Oneri: Normal personellere Local Admin yetkisi verilmemelidir (LAPS kullanin)." -ForegroundColor Yellow;
} else {
    Write-Host "  [OK] GUVENLI: Yerel admin grubunda sadece yetkili standart hesaplar mevcut." -ForegroundColor Green;
}
Write-Host "==========================================================`n" -ForegroundColor Yellow;

