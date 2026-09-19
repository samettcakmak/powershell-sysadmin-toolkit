<#

======================================================================
!!! KULLANMADAN ONCE DEGISTIRILMESI GEREKEN YERLER !!!
Bu betigi kendi ortaminizda calistirmadan once kod icerisindeki 
asagidaki 3 temel ayari kendi sirketinize gore guncelleyiniz:

1. Karantina Klasoru Yolu (DisabledOU): "DC=samet,DC=local" kismini kendi domaininize gore duzenleyin.
2. Islem Yapan Kisi (Operator): "Samet Cakmak" ismini kendi adinizla degistirin.
3. Otomatik OU Olusturma Yolu (Path): Ana dizin yolunu ("DC=samet,DC=local") kendi domaininize gore duzenleyin.
======================================================================

.SYNOPSIS
    Active Directory Personel Isten Ayrilis (Offboarding) Guvenlik Otomasyonu.
.DESCRIPTION
    Isten ayrilan personellerin Active Directory hesabini derhal dondurur,
    tum yetki gruplarindan cikarir (birincil grup haric), aciklama alanina
    ayrilis tarihini isler ve hesabi 'Disabled_Users' karantina OU'suna tasir.
    Eger 'Disabled_Users' OU'su yoksa otomatik olarak olusturur.
.PARAMETER Username
    Islem yapilacak kullanicinin Active Directory kullanici adi (SamAccountName). (Orn: ahmet.yilmaz)
.PARAMETER DisabledOU
    Karantina / Pasif kullanicilar klasorunun tam yolu. Belirtilmezse varsayilan dizin kullanilir.
.PARAMETER Operator
    Islemi gerceklestiren kisinin adi veya unvani. Bu bilgi kullanicinin aciklama (Description) alanina islenir.
.EXAMPLE
    .\Remove-ADUserOffboarding.ps1 -Username "ahmet.yilmaz"
    (Sadece kullanici adi girilerek en hizli ve varsayilan sekilde calistirilir.)
.EXAMPLE
    .\Remove-ADUserOffboarding.ps1 -Username "zeynep.kaya" -Operator "Helpdesk Ekibi"
    (Islemi yapan kisinin bilgisini degistirerek calistirir.)
.NOTES
    Yazar : Samet Cakmak
    Surum : 1.2.0 (Otomatik OU Olusturma ve Splatting Yapisi)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [string]$DisabledOU = "OU=Disabled_Users,OU=Samet_Holding,DC=samet,DC=local",

    [Parameter(Mandatory = $false)]
    [string]$Operator = "Samet Cakmak (IT Admin)"
)

Write-Host "==========================================================" -ForegroundColor Red
Write-Host "  ACTIVE DIRECTORY OFFBOARDING / HESAP DONDURMA" -ForegroundColor Red
Write-Host "  Hazirlayan: Samet Cakmak" -ForegroundColor Red
Write-Host "==========================================================" -ForegroundColor Red

$dateStamp = (Get-Date -Format "yyyy-MM-dd HH:mm")
Write-Host "-> Hedef Kullanici: $Username" -ForegroundColor Yellow

if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    try {
        $user = Get-ADUser -Identity $Username -Properties MemberOf, Description -ErrorAction Stop

        # --- OU KONTROLU VE OTOMATIK OLUSTURMA ---
        $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq 'Disabled_Users'" -ErrorAction SilentlyContinue
        if (-not $ouExists) {
            Write-Host "  [!] 'Disabled_Users' OU'su bulunamadi, ana dizinde otomatik olusturuluyor..." -ForegroundColor Yellow
            New-ADOrganizationalUnit -Name "Disabled_Users" -Path "DC=samet,DC=local" -ErrorAction Stop
        }

        # 1. Hesabi Devre Disi Birak (Disable)
        Disable-ADAccount -Identity $user -ErrorAction Stop
        Write-Host "  [OK] Kullanici hesabi devre disi birakildi (Disabled)." -ForegroundColor Green

        # 2. Aciklama (Description) Guncelle
        $newDesc = "ISTEN AYRILDI | Tarih: $dateStamp | Islem Yapan: $Operator | Eski Aciklama: $($user.Description)"
        $setParams = @{
            Identity    = $user
            Description = $newDesc
            ErrorAction = 'Stop'
        }
        Set-ADUser @setParams
        Write-Host "  [OK] Aciklama alani guvenlik notuyla guncellendi." -ForegroundColor Green

        # 3. Guvenlik Gruplarindan Cikar (Domain Users haric)
        $groups = $user.MemberOf
        foreach ($grp in $groups) {
            Remove-ADGroupMember -Identity $grp -Members $user -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Host "  [OK] Tum yetki ve departman guvenlik gruplarindan temizlendi." -ForegroundColor Green

        # 4. Karantina / Disabled OU'suna Tasi
        $moveParams = @{
            Identity    = $user.DistinguishedName
            TargetPath  = $DisabledOU
            ErrorAction = 'Stop'
        }
        Move-ADObject @moveParams
        Write-Host "  [OK] Hesap '$DisabledOU' karantina klasorune tasindi." -ForegroundColor Green

        Write-Host "`n[GUVENLIK TAMAMLANDI] $Username hesabi basariyla kapatildi ve yetkileri sifirlandi.`n" -ForegroundColor Cyan
    }
    catch {
        Write-Host "`n[HATA] Islem basarisiz: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  [SIMULASYON] Hesap donduruldu, gruplar temizlendi, $DisabledOU konumuna tasindi." -ForegroundColor Magenta
}