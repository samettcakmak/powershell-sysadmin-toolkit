<#
.SYNOPSIS
    Yerel Yönetici (Local Administrators) Güvenlik Denetim Betiği.
.DESCRIPTION
    Bilgisayardaki 'Administrators' grubuna dahil olan kullanıcı ve grupları listeler.
    Standart kullanıcıların veya yetkisiz hesapların local admin olup olmadığını
    denetler ve güvenlik riski oluşturan hesapları raporlar.
.EXAMPLE
    .\Audit-LocalAdminAccounts.ps1
.NOTES
    Yazar : Samet Çakmak
    Sürüm : 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$AuthorizedAdmins = @("Administrator", "Domain Admins")
)

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  YEREL YÖNETİCİ (LOCAL ADMIN) GÜVENLİK AUDIT BETİĞİ" -ForegroundColor Yellow
Write-Host "  Hazırlayan: Samet Çakmak" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue

if (-not $admins) {
    Write-Host "[!] 'Administrators' grubu okunamadı veya boş." -ForegroundColor Red
    exit
}

Write-Host "[-] Denetlenen Cihaz: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "[-] Toplam Local Admin Sayısı: $($admins.Count)`n" -ForegroundColor Cyan

$flaggedCount = 0

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
        Write-Host "  [RISK - İNCELEME GEREKİR] $name ($class)" -ForegroundColor Red
        $flaggedCount++
    }
}

Write-Host "`n==========================================================" -ForegroundColor Yellow
if ($flaggedCount -gt 0) {
    Write-Host "  [!] UYARI: $flaggedCount adet yetkisiz veya şüpheli Local Admin tespit edildi!" -ForegroundColor Red
    Write-Host "  Öneri: Normal personellere Local Admin yetkisi verilmemelidir (LAPS kullanın)." -ForegroundColor Yellow
} else {
    Write-Host "  [✓] GÜVENLİ: Yerel admin grubunda sadece yetkili standart hesaplar mevcut." -ForegroundColor Green
}
Write-Host "==========================================================`n" -ForegroundColor Yellow
