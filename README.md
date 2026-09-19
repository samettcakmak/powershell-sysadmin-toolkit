# ⚡ PowerShell Sysadmin Toolkit

> **Kurumsal sistem yöneticileri, IT operasyon ekipleri ve Active Directory yöneticileri için üretim ortamında test edilmiş PowerShell otomasyon ve denetim araçları.**

[![Author: Samet Çakmak](https://img.shields.io/badge/Author-Samet%20Çakmak-blue.svg)](https://github.com/samettcakmak)
[![Platform: Windows Server](https://img.shields.io/badge/Platform-Windows%20Server-0078D6.svg)](https://www.microsoft.com/)
[![PowerShell: 5.1%2B%20%7C%207%2B](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📌 Proje Amacı

Bir sistem yöneticisinin mesaisinin büyük bölümü kullanıcı açma/kapatma, sunucu disk doluluklarını kontrol etme ve yerel yetkileri denetleme gibi manuel rutinlerle geçer. Bu toolkit; bu süreçleri **hata payını sıfıra indiren, güvenlik standartlarına uygun ve tek tıkla çalışan modüler PowerShell betikleri** ile otomatize etmek için geliştirilmiştir.

---

## 🗂️ Araç Kütüphanesi ve Modüller

```text
powershell-sysadmin-toolkit/
│
├── 01-Active-Directory/
│   ├── New-ADUserBulkOnboarding.ps1    # CSV'den toplu kullanıcı açma, 16 karakter şifre, Otomatik OU/Grup oluşturma
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
İK'dan gelen CSV dosyasını okuyarak kullanıcıları oluşturur, rastgele 16 karakterlik karmaşık geçici şifre atar ve departman güvenlik grubuna ekler. Departmana ait OU veya Güvenlik Grubu Active Directory'de yoksa otomatik olarak oluşturur:

PowerShell
cd 01-Active-Directory
.\New-ADUserBulkOnboarding.ps1 -CsvPath ".\users_sample.csv" -DomainName "holding.local"
İşlem bitiminde oluşan Onboarding_Results.csv dosyasında üretilen geçici şifreler güvenli iletim için listelenir.

2. Personel İşten Ayrılış (Offboarding)
Ayrılan personelin hesabını derhal kapatır, gruplardan temizler, açıklama alanına zaman damgası düşer ve karantina OU'suna taşır. Karantina OU'su dizinde bulunmuyorsa otomatik olarak oluşturur:

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

Yetenek Kazanım Uzman Yardımcısı @ Özak Global Holding | Sistem ve Otomasyon Geliştiricisi

LinkedIn & GitHub üzerinden takip edebilirsiniz.

📄 Lisans
Bu proje MIT Lisansı kapsamında açık kaynak olarak yayınlanmıştır.