<#
.SYNOPSIS
    Active Directory Toplu Kullanici Acma ve Yetkilendirme Otomasyonu.
.DESCRIPTION
    Bu betik, IK veya yonetimden gelen bir CSV dosyasini okuyarak kullanici hesaplarini
    otomatik olarak olusturur, karmasik gecici sifre atar, ilk giriste 
    sifre degisimini zorunlu kilar ve departman guvenlik gruplarina ekler.
.PARAMETER CsvPath
    Kullanici bilgilerini iceren CSV dosyasinin yolu.
.PARAMETER DomainName
    Kullanicilarin UPN soneki olacak alan adi (Orn: holding.local).
.PARAMETER BaseOU
    Kullanicilarin eklenecegi ana OU yolu (Orn: "OU=Sirket_Personelleri,DC=holding,DC=local").
.EXAMPLE
    .\New-ADUserBulkOnboarding.ps1 -CsvPath ".\users_sample.csv" -DomainName "holding.local"
.NOTES
    Yazar : Samet Cakmak
    Surum : 1.5.0 (Saf ASCII, Donusum Fonksiyonu Kaldirildi)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = ".\users_sample.csv",

    [Parameter(Mandatory = $false)]
    [string]$DomainName = "samet.local",

    [Parameter(Mandatory = $false)]
    [string]$BaseOU = "OU=Samet_Holding,DC=samet,DC=local",

    [Parameter(Mandatory = $false)]
    [string]$LogExportPath = ".\Onboarding_Results.csv"
)

# 1. Rastgele Guvenli Sifre Uretici Fonksiyonu (16 Karakter Karmasik)
function New-RandomPassword {
    param ([int]$Length = 16)
    $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    $lower = "abcdefghijkmnopqrstuvwxyz";
    $digits = "23456789";
    $symbols = "!@#$%^&*";
    $all = $upper + $lower + $digits + $symbols;

    $rng = New-Object System.Random;
    $password = New-Object System.Text.StringBuilder;

    [void]$password.Append($upper[$rng.Next(0, $upper.Length)]);
    [void]$password.Append($lower[$rng.Next(0, $lower.Length)]);
    [void]$password.Append($digits[$rng.Next(0, $digits.Length)]);
    [void]$password.Append($symbols[$rng.Next(0, $symbols.Length)]);

    for ($i = 4; $i -lt $Length; $i++) {
        [void]$password.Append($all[$rng.Next(0, $all.Length)]);
    }
    
    # Satir birlestirme hatalarina karsi noktali virgul ile koruma eklendi
    $charArray = $password.ToString().ToCharArray();
    for ($i = 0; $i -lt $charArray.Length; $i++) {
        $j = $rng.Next(0, $charArray.Length);
        $tmp = $charArray[$i];
        $charArray[$i] = $charArray[$j];
        $charArray[$j] = $tmp;
    }
    return -join $charArray;
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  ACTIVE DIRECTORY TOPLU KULLANICI ACMA OTOMASYONU" -ForegroundColor Cyan
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 2. CSV Dosyasi Kontrolu
if (-not (Test-Path $CsvPath)) {
    Write-Error "Belirtilen CSV dosyasi bulunamadi: $CsvPath"
    exit 1
}

$users = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Host "[+] CSV okundu. Toplam $($users.Count) adet kullanici kaydi islenecek.`n" -ForegroundColor Green

$results = @()

foreach ($row in $users) {
    $firstName = $row.FirstName.Trim()
    $lastName  = $row.LastName.Trim()
    $department = $row.Department.Trim()
    $title      = $row.Title.Trim()
    $manager    = $row.ManagerEmail.Trim()

    # Isimler dogrudan kucuk harfe cevrilir (Bosluk varsa silinir)
    $cleanFirst = $firstName.ToLower().Replace(' ', '')
    $cleanLast  = $lastName.ToLower().Replace(' ', '')
    $username   = "$cleanFirst.$cleanLast"
    $upn        = "$username@$DomainName"
    $displayName = "$firstName $lastName"
    
    $tempPassword = New-RandomPassword -Length 16
    $securePassword = ConvertTo-SecureString $tempPassword -AsPlainText -Force

    # Departman OU Yolu
    $targetOU = "OU=$department,$BaseOU"

    Write-Host "-> Isleniyor: $displayName ($username) | Departman: $department" -NoNewline

    try {
        if (Get-Module -ListAvailable -Name ActiveDirectory) {
            Import-Module ActiveDirectory -ErrorAction SilentlyContinue

            # Kullanici zaten var mi kontrolu
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue
            if ($existingUser) {
                Write-Host " [UYARI: Kullanici Zaten Mevcut]" -ForegroundColor Yellow
                $status = "Zaten Mevcut"
            } else {
                
                # Kullanici olusturma parametreleri
                $adUserParams = @{
                    Name                  = $displayName
                    SamAccountName        = $username
                    UserPrincipalName     = $upn
                    DisplayName           = $displayName
                    GivenName             = $firstName
                    Surname               = $lastName
                    Department            = $department
                    Title                 = $title
                    Path                  = $targetOU
                    AccountPassword       = $securePassword
                    Enabled               = $true
                    ChangePasswordAtLogon = $true
                }
                
                New-ADUser @adUserParams -ErrorAction Stop

                # Departman Guvenlik Grubuna Ekle (Orn: GRP_Muhasebe)
                $groupName = "GRP_$department"
                $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue
                if ($group) {
                    Add-ADGroupMember -Identity $group -Members $username -ErrorAction SilentlyContinue
                }

                Write-Host " [BASARILI]" -ForegroundColor Green
                $status = "Basarili"
            }
        } else {
            Write-Host " [SIMULASYON: Basarili]" -ForegroundColor Magenta
            $status = "Simule Edildi"
        }

        $results += [PSCustomObject]@{
            Username      = $username
            DisplayName   = $displayName
            Department    = $department
            Title         = $title
            UserPrincipal = $upn
            TempPassword  = $tempPassword
            Status        = $status
            CreatedTime   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }
    catch {
        Write-Host " [HATA: $($_.Exception.Message)]" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Username      = $username
            DisplayName   = $displayName
            Department    = $department
            Title         = $title
            UserPrincipal = $upn
            TempPassword  = "N/A"
            Status        = "HATA: $($_.Exception.Message)"
            CreatedTime   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }
}

# 3. Sonuc Raporunun Disa Aktarilmasi
$results | Export-Csv -Path $LogExportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "[OK] Islem tamamlandi! Kullanici sifre listesi kaydedildi: $LogExportPath" -ForegroundColor Green
Write-Host ""
Write-Host "[UYARI] Bu listeyi IK veya ilgili birim yoneticisine guvenli kanaldan iletiniz." -ForegroundColor DarkGray