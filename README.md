# ⚡ PowerShell Sysadmin Toolkit

[🇹🇷 Türkçe Dokümantasyon](#türkçe-dokümantasyon) | [🇬🇧 English Documentation](#english-documentation)

[![Author: Samet Çakmak](https://img.shields.io/badge/Author-Samet%20Çakmak-blue.svg)](https://github.com/samettcakmak)
[![Platform: Windows Server](https://img.shields.io/badge/Platform-Windows%20Server-0078D6.svg)](https://www.microsoft.com/)
[![PowerShell: 5.1%2B%20%7C%207%2B](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

<a id="english-documentation"></a>
## 🇬🇧 English Documentation

> **Production-tested PowerShell automation and auditing tools for enterprise system administrators, IT operations teams, and Active Directory managers.**

### 📌 Project Purpose
A significant portion of a system administrator's shift is spent on manual routines such as user onboarding/offboarding, checking server disk spaces, and auditing local privileges. This toolkit is developed to automate these processes with **modular, click-to-run PowerShell scripts that eliminate human error and strictly adhere to security standards.**

### 🗂️ Tool Library and Modules

```text
powershell-sysadmin-toolkit/
│
├── 01-Active-Directory/
│   ├── New-ADUserBulkOnboarding.ps1    # Bulk user creation, 16-char password gen, auto-OU/Group creation
│   ├── Remove-ADUserOffboarding.ps1    # Automated account disabling, permission cleanup, and quarantine
│   └── users_sample.csv               # Sample CSV dataset for testing
│
├── 02-Monitoring-and-Health/
│   └── Get-ServerHealthReport.ps1      # HTML reporter for Disk, RAM, Uptime, and critical services
│
└── 03-Security-and-Audit/
    └── Audit-LocalAdminAccounts.ps1    # Privilege escalation audit for local 'Administrators' group
🚀 Quick Start and Usage
1. Bulk User Onboarding
Reads the HR-provided CSV file, generates secure 16-character temporary passwords, adds users to appropriate department security groups, and automatically creates missing Organizational Units (OUs) or Groups if they do not exist:

PowerShell
cd 01-Active-Directory
.\New-ADUserBulkOnboarding.ps1 -CsvPath ".\users_sample.csv" -DomainName "holding.local"
Generated passwords are exported to Onboarding_Results.csv for secure transmission.

2. User Offboarding (Account Termination)
Immediately disables the departing employee's account, strips all group memberships, adds a timestamp to the description, and moves the account to the quarantine OU. Automatically detects the current Domain:

PowerShell
cd 01-Active-Directory
.\Remove-ADUserOffboarding.ps1 -Username "ahmet.yilmaz"
3. Server Health Report (HTML)
Checks server disk spaces (flags red if below 10%), memory usage, and critical Windows services to generate a modern HTML web report:

PowerShell
cd 02-Monitoring-and-Health
.\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
4. Local Admin Security Audit
Detects if standard users have gained unauthorized local administrator privileges (Privilege Escalation detection):

PowerShell
cd 03-Security-and-Audit
.\Audit-LocalAdminAccounts.ps1
⚙️ Requirements
Windows PowerShell 5.1 or PowerShell 7+

Active Directory Administrative Tools (RSAT / ActiveDirectory Module)

Run as Administrator privileges

👤 Author
Samet Çakmak

Management Information Systems (MIS) / System & Network Administration

Follow on LinkedIn & GitHub.

📄 License
This project is open-source and licensed under the MIT License.

🇹🇷 Türkçe Dokümantasyon
Kurumsal sistem yöneticileri, IT operasyon ekipleri ve Active Directory yöneticileri için üretim ortamında test edilmiş PowerShell otomasyon ve denetim araçları.

📌 Proje Amacı
Bir sistem yöneticisinin mesaisinin büyük bölümü kullanıcı açma/kapatma, sunucu disk doluluklarını kontrol etme ve yerel yetkileri denetleme gibi manuel rutinlerle geçer. Bu toolkit; bu süreçleri hata payını sıfıra indiren, güvenlik standartlarına uygun ve tek tıkla çalışan modüler PowerShell betikleri ile otomatize etmek için geliştirilmiştir.

🗂️ Araç Kütüphanesi ve Modüller

powershell-sysadmin-toolkit/
│
├── 01-Active-Directory/
│   ├── New-ADUserBulkOnboarding.ps1    # CSV'den toplu kullanıcı açma, 16 karakter şifre, Otomatik OU/Grup açma
│   ├── Remove-ADUserOffboarding.ps1    # Personel ayrılışında hesabı dondurma, yetki temizliği ve karantina
│   └── users_sample.csv               # Test amaçlı örnek kullanıcı veri seti
│
├── 02-Monitoring-and-Health/
│   └── Get-ServerHealthReport.ps1      # Disk, RAM, Uptime ve kritik servislerin HTML raporlayıcısı
│
└── 03-Security-and-Audit/
    └── Audit-LocalAdminAccounts.ps1    # Yerel 'Administrators' grubundaki yetki denetimi

🚀 Hızlı Başlangıç ve Kullanım
1. Toplu Kullanıcı Açma (Onboarding)
İK'dan gelen CSV dosyasını okuyarak kullanıcıları oluşturur, rastgele 16 karakterlik karmaşık geçici şifre atar, departman güvenlik grubuna ekler. Departmana ait OU veya Güvenlik Grubu Active Directory'de yoksa otomatik olarak oluşturur:

PowerShell
cd 01-Active-Directory
.\New-ADUserBulkOnboarding.ps1 -CsvPath ".\users_sample.csv" -DomainName "holding.local"
İşlem bitiminde oluşan Onboarding_Results.csv dosyasında üretilen geçici şifreler güvenli iletim için listelenir.

2. Personel İşten Ayrılış (Offboarding)
Ayrılan personelin hesabını derhal kapatır, gruplardan temizler, açıklama alanına zaman damgası düşer ve karantina OU'suna taşır. Bulunduğu etki alanını (Domain) otomatik tespit eder:

PowerShell
cd 01-Active-Directory
.\Remove-ADUserOffboarding.ps1 -Username "ahmet.yilmaz"
3. Sunucu Sağlık ve Durum Raporu (HTML)
Sunucunun disk doluluklarını (kalan %10 altı ise kırmızı uyarı), bellek kullanımını ve kritik Windows servislerini denetleyip modern bir web raporu üretir:

PowerShell
cd 02-Monitoring-and-Health
.\Get-ServerHealthReport.ps1 -OutputHtmlPath ".\ServerHealthReport.html"
4. Yerel Admin Güvenlik Denetimi
Standart kullanıcıların bilgisayarlarda yerel yönetici yetkisi alıp almadığını denetler (Privilege Escalation tespiti):

PowerShell
cd 03-Security-and-Audit
.\Audit-LocalAdminAccounts.ps1
⚙️ Gereksinimler
Windows PowerShell 5.1 veya PowerShell 7+

Active Directory Yönetim Araçları (RSAT / ActiveDirectory Module)

Yönetici (Run as Administrator) yetkisi

👤 Hazırlayan
Samet Çakmak

Yönetim Bilişim Sistemleri (MIS) / Sistem ve Ağ Yönetimi

LinkedIn & GitHub üzerinden takip edebilirsiniz.

📄 Lisans
Bu proje MIT Lisansı kapsamında açık kaynak olarak yayınlanmıştır.