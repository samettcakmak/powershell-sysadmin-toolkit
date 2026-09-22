# ⚡ PowerShell Sysadmin Toolkit

> **Kurumsal sistem yöneticileri, IT operasyon ekipleri ve Active Directory yöneticileri için üretim ortamında test edilmiş PowerShell otomasyon, sistem sağlığı izleme ve güvenlik denetim araç seti.**

[![Author: Samet Çakmak](https://img.shields.io/badge/Author-Samet%20Çakmak-blue.svg)](https://github.com/samettcakmak)
[![Platform: Windows Server & Client](https://img.shields.io/badge/Platform-Windows%20Server%20%7C%2010%20%7C%2011-0078D6.svg)](https://www.microsoft.com/)
[![PowerShell: 5.1%2B %7C 7%2B](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)
[![Edition: Enterprise SOC & Hybrid](https://img.shields.io/badge/Edition-Enterprise%20SOC%20%26%20Hybrid-10B981.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📌 Proje Amacı

Bir sistem yöneticisinin mesaisinin büyük bölümü kullanıcı açma/kapatma, sunucu donanım ve servis sağlığını izleme ile yerel yönetici yetkilerini denetleme gibi manuel rutinlerle geçer.

Bu toolkit; tüm bu operasyonel süreçleri **hata payını sıfıra indiren, güvenlik standartlarına uygun (Least Privilege / LAPS prensipleri), modern görsel panellere (Zero-Scroll SOC Dark Dashboard) sahip ve otomatik yetki yükseltmeli modüler PowerShell betikleri** ile tek merkezden otomatize etmek amacıyla geliştirilmiştir.

---

## 🗂️ Araç Kütüphanesi ve Dizin Yapısı

```text
powershell-sysadmin-toolkit/
│
├── 01-Active-Directory/
│   ├── New-ADUserBulkOnboarding.ps1    # CSV'den toplu kullanıcı açma, TR karakter normalizasyonu & şifre üretimi
│   ├── Remove-ADUserOffboarding.ps1    # Personel ayrılışında hesabı dondurma, grup temizleme ve karantina OU
│   └── users_sample.csv               # Test ve demo amaçlı örnek personel veri seti
│
├── 02-Monitoring-and-Health/
│   └── Get-ServerHealthReport.ps1      # v3.1 Zero-Scroll SOC Dark Dashboard, Conic Gauges & Privacy Shield
│
└── 03-Security-and-Audit/
    └── Audit-LocalAdminAccounts.ps1    # v2.2 DC & Client Hibrit, UAC Self-Elevation & İnteraktif Remediation
```

---

## 🚀 Modüller ve Öne Çıkan Geliştirmeler

### 1. Active Directory: Toplu Kullanıcı Açma (Bulk Onboarding)
İK biriminden gelen CSV personel listesini otomatik okur; kurumsal standartlarda Active Directory hesaplarını saniyeler içinde oluşturur.

```powershell
cd 01-Active-Directory
.\New-ADUserBulkOnboarding.ps1 -CsvPath ".\users_sample.csv" -DomainName "holding.local"
```

* **Türkçe Karakter Normalizasyonu:** İsimlerdeki `ç, ğ, ı, ö, ş, ü` ve büyük harf türevlerini otomatik olarak `c, g, i, o, s, u` karakterlerine dönüştürerek SAMAccountName ve UPN hatalarını engeller.
* **Güvenli Geçici Şifre:** Her kullanıcı için 12 karakterlik karmaşık geçici şifre üretir ve ilk oturum açılışında şifre değişimini zorunlu tutar (`ChangePasswordAtLogon = $true`).
* **Departman Grubu Ataması:** Personeli CSV'de belirtilen departman güvenlik grubuna otomatik dahil eder.
* **Denetim Çıktısı:** İşlem sonunda kullanıcı adı ve geçici şifreleri içeren `Onboarding_Results.csv` raporu oluşturur.

---

### 2. Active Directory: Güvenli Personel Ayrılışı (Offboarding)
İşten ayrılan personelin erişim yetkilerini hızla sıfırlayarak kurumsal yetki sızıntısını önler.

```powershell
cd 01-Active-Directory
.\Remove-ADUserOffboarding.ps1 -Username "ahmet.yilmaz" -DisabledOU "OU=Disabled_Users,DC=holding,DC=local"
```

* **Hesap Dondurma:** Kullanıcı hesabını anında devre dışı bırakır (`Disable-ADAccount`).
* **Yetki Temizliği:** Kullanıcının üye olduğu tüm departman, VPN ve kaynak yetki gruplarını siler (birincil `Domain Users` hariç).
* **Zaman Damgalı Loglama:** Kullanıcı nesnesinin `Description` (Açıklama) alanına ayrılış tarihi, saati ve işlemi yapan admin bilgisini damgalar.
* **Karantina OU'suna Taşıma:** Hesabı doğrudan devre dışı bırakılmış kullanıcılar için ayrılan karantina organizasyonel birimine (`DisabledOU`) taşır.

---

### 3. Sunucu Sağlık ve Performans Paneli (Get-ServerHealthReport v3.1)
Windows sunucuların genel durumunu tek ekranda toplayan, modern kurumsal **SOC Dark Edition** HTML dashboard'u.

```powershell
cd 02-Monitoring-and-Health
.\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
```

#### 🌟 V3.1 ile Eklenen Modern Özellikler:
* **Zero-Scroll SOC Arayüzü:** Standart 1080p monitörlere dikey kaydırma çubuğu gerektirmeden tam oturan modern koyu tema (Dark Glassmorphism).
* **Radial Conic Gauges:** CPU ve RAM yüklerini kullanım oranına göre renk değiştiren (Yeşil / Sarı / Kırmızı) dairesel ibrelerle sunar.
* **Görsel Depolama Barları:** Disk doluluk oranlarını dinamik ilerleme çubuklarıyla gösterir (%10'un altına indiğinde kritik uyarı verir).
* **En Çok Kaynak Tüketen Süreçler (Top 5 Processes):** Sunucuda en çok bellek harcayan ilk 5 işlemi anlık listeler.
* **Ağ Kartları ve IP Yapılandırması:** Aktif bağdaştırıcıları, bağlantı hızlarını ve IP adreslerini listeler.
* **🛡️ Gizlilik Kalkanı (Privacy Mode Toggle):** LinkedIn veya GitHub'da ekran görüntüsü paylaşırken kurumsal IP adreslerini ve sunucu adını tek tıkla gizleyen/bulanıklaştıran interaktif buton.

---

### 4. Yerel Admin Güvenlik Denetimi & İyileştirme (Audit-LocalAdminAccounts v2.2)
Kurumsal ağdaki en kritik güvenlik açıklarından biri olan standart kullanıcıların yerel yönetici hakkı elde etmesini (**Privilege Escalation**) denetler ve interaktif olarak çözer.

```powershell
cd 03-Security-and-Audit
.\Audit-LocalAdminAccounts.ps1
```

#### 🌟 V2.2 ile Eklenen Yetenekler:
* **DC & Client Hibrit Mimarisi:** Çalıştığı cihazın **Domain Controller (DC)** mı yoksa **İstemci (Client)** mi olduğunu dinamik algılar. DC üzerinde Active Directory `BUILTIN\Administrators` grubunu, istemcide ise yerel SAM veritabanını tarar.
* **Otomatik Yönetici Yükseltme (Self-Elevation):** Yönetici olarak açılmadığında kullanıcıdan otomatik **UAC onayı** isteyerek kendini tam yetkili başlatır; çift tıklamayla çalıştırılabilir.
* **İnteraktif Güvenlik İyileştirmesi (Remediation):** Tespit edilen yetkisiz veya şüpheli hesapları numaralandırılmış menü ile tek tek (`[1]`, `[2]`) veya topluca (`[A]`) Administrators grubundan güvenli teyit alarak kaldırır.

```text
==========================================================
  YEREL YONETICI (LOCAL ADMIN) DENETIM & TEMIZLEME ARACI 
  Hazirlayan: Samet Cakmak | Surum 2.2
==========================================================
[-] Hedef Cihaz : CLIENT01
[-] Cihaz Rolu  : Istemci / Uye Sunucu
[-] Yetki Durumu: YONETICI (ELEVATED ADMIN) [OK]
[-] Toplam Yonetici Sayisi: 3

  [OK - Yetkili] CLIENT01\Administrator (User)
  [RISK - INCELEME GEREKIR] CLIENT01\Client01 (User)
  [OK - Yetkili] SAMET\Domain Admins (Group)

==========================================================
  [!] UYARI: 1 adet yetkisiz/riskli hesap tespit edildi!
==========================================================

--- ISLEM MENUSU ---
  [1] CLIENT01\Client01 hesabini Administrators grubundan cikar
  [0] Cikis (Hicbir islem yapma)

Lutfen yapmak istediginiz islemi secin: 1
[?] 'CLIENT01\Client01' hesabini Administrators grubundan cikarmak istediginize emin misiniz? (E/H): E
[+] BASARILI: 'CLIENT01\Client01' basariyla Administrators grubundan kaldirildi!
```

---

## ❓ Sık Karşılaşılan Sorunlar ve Çözümleri (Troubleshooting)

### ⚠️ "Running scripts is disabled on this system" veya Sağ Tıkta Pencerenin Anında Kapanması

**Belirti:**
Bir `.ps1` betiğini çalıştırmak istediğinizde veya sağ tıklayıp **"Run with PowerShell"** dediğinizde konsolda şu hatayı alabilirsiniz ya da pencere saliseler içinde açılıp kapanabilir:
```text
File ... cannot be loaded because running scripts is disabled on this system.
+ CategoryInfo          : SecurityError: (:) [], ParentContainsErrorRecordException
+ FullyQualifiedErrorId : UnauthorizedAccess
```

**Nedeni:**
Windows istemcilerinde (Windows 10/11) PowerShell'in varsayılan güvenlik politikası (`ExecutionPolicy`), zararlı yazılımların arka planda izinsiz kod çalıştırmasını engellemek için **`Restricted`** (kısıtlı) olarak gelir.

**Çözüm 1: Kalıcı Sistem İzni (Tavsiye Edilen)**
Sisteminizde PowerShell betiklerini ve sağ tık menüsünü sorunsuz kullanabilmek için bir defaya mahsus şu adımı uygulayın:
1. Başlat menüsüne **PowerShell** yazın ve **"Yönetici olarak çalıştır"** (Run as Administrator) seçeneğiyle açın.
2. Aşağıdaki komutu yapıştırıp **Enter**'a basın:
   ```powershell
   Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
   ```
*(Bu ayar, yerel olarak kendi yazdığınız betiklerin engelsiz çalışmasını sağlarken internetten indirilen güvenilmeyen betikleri korumaya devam eder.)*

**Çözüm 2: Tek Seferlik Geçici Çalıştırma (Bypass)**
Sistem genelindeki politikayı değiştirmeden sadece ilgili betiği tek seferlik çalıştırmak için:
```powershell
powershell -ExecutionPolicy Bypass -File .\BetikAdi.ps1
```

---

## ⚙️ Sistem Gereksinimleri
* **İşletim Sistemi:** Windows Server 2016 / 2019 / 2022 / 2025 veya Windows 10 / 11
* **PowerShell:** Windows PowerShell 5.1 veya PowerShell 7+
* **Gerekli Modüller:** ActiveDirectory (RSAT - yalnızca AD yönetimi içeren 01 modülü için)
* **Çalıştırma Yetkisi:** Yönetici (Administrator) yetkisi *(Audit betiği yetkisiz açıldığında UAC yükseltmesini otomatik yapar)*

---

## 👤 Hazırlayan

**Samet Çakmak**  
*Yönetim Bilişim Sistemleri (MIS) | Sistem ve Ağ Yönetimi | Siber Güvenlik*  
*LinkedIn & GitHub üzerinden projelerimi ve çalışmalarımı takip edebilirsiniz.*

---

## 📄 Lisans
Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak paylaşılmıştır.

