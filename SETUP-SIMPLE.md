# 🆘 AI Cleaner iOS - ACİL DURUM KURULUMU

Xcode crash ediyor mu? Dosyalar karışık mı? Bu rehber **%100 çalışır**.

---

## ⚡ HIZLI ÇÖZÜM (5 Dakika)

### Adım 1: Temizlik Scripti Çalıştır

Terminal'de:

```bash
cd ~/workspaces/ai-ios-cleaner
./cleanup.sh
```

Bu script:
- ✅ Bozuk Xcode projelerini siler
- ✅ DerivedData temizler
- ✅ Xcode cache'ini siler
- ✅ Xcode'u kapatır

### Adım 2: Mac'i Yeniden Başlat

Cidden. Xcode bazen sadece yeniden başlatmayla düzelir.

```bash
# Ya da sadece logout/login yapın
```

### Adım 3: YENİ YAKLAŞIM - Ayrı Klasörde Proje Oluştur

Şimdi projeyi **ai-ios-cleaner klasörünün DIŞINDA** oluşturacağız!

1. **Xcode'u açın**
2. **File → New → Project**
3. **iOS → App** → Next
4. Ayarlar:
   - Product Name: `AI Cleaner`
   - Team: Kendiniz
   - Organization ID: `com.aicleaner`
   - Interface: **SwiftUI** ✅
   - Storage: **Core Data** ✅
   - Next

5. **ÖNEMLİ** - Kayıt yeri:
   - **Desktop'a kaydedin!** (ya da Documents)
   - "Create Git repository" ❌ KAPAT
   - Create

Şimdi şu yapınız var:
```
Desktop/
└── AI Cleaner/              ← Xcode projesi
    ├── AI Cleaner.xcodeproj
    └── AI Cleaner/

workspaces/
└── ai-ios-cleaner/          ← Kaynak kodlar
    └── AI Cleaner/
        ├── App/
        ├── Core/
        └── ...
```

---

## 🎯 Dosyaları DOĞRU Şekilde Ekle

### Adım 4: Xcode'un Dosyalarını SİL

Xcode projesinde sol panelde şunları **SİL** (Move to Trash):

- `AI_CleanerApp.swift`
- `ContentView.swift`
- `Persistence.swift`
- `AI_Cleaner.xcdatamodeld`
- `Assets.xcassets`
- `Preview Content` klasörü

### Adım 5: Kaynak Klasörleri REFERANS Olarak Ekle

**ÇOK ÖNEMLİ:** Copy etmeden, sadece referans olarak ekleyeceğiz!

1. **File → Add Files to "AI Cleaner"...**

2. Navigate to: `~/workspaces/ai-ios-cleaner/AI Cleaner/`

3. **TEK TEK** şu 4 klasörü ekle:

   **İlk ekleme - App klasörü:**
   - `App` klasörünü seç
   - Alt kısımda:
     - ❌ **"Copy items if needed"** - KAPALI OLMALI
     - ✅ **"Create groups"**
     - ✅ **"Add to targets: AI Cleaner"**
   - **Add**

   **İkinci ekleme - Core klasörü:**
   - `Core` klasörünü seç
   - Aynı ayarlar
   - **Add**

   **Üçüncü ekleme - Features klasörü:**
   - `Features` klasörünü seç
   - Aynı ayarlar
   - **Add**

   **Dördüncü ekleme - Resources klasörü:**
   - `Resources` klasörünü seç
   - Aynı ayarlar
   - **Add**

### Adım 6: Info.plist Yolunu Ayarla

1. Sol panelde **AI Cleaner** projesine tıkla (en üstteki mavi simge)
2. **TARGETS → AI Cleaner** seç
3. **Build Settings** tab
4. Arama: `Info.plist File`
5. Değerini şuna çevir:

```
/Users/KULLANICI_ADINIZ/workspaces/ai-ios-cleaner/AI Cleaner/Resources/Info.plist
```

**Tam yolu bulmak için:**

Terminal'de:
```bash
cd ~/workspaces/ai-ios-cleaner/AI\ Cleaner/Resources/
pwd
# Çıktıyı kopyala ve sonuna /Info.plist ekle
```

### Adım 7: Swift Package Dependencies

**File → Add Package Dependencies...**

**RevenueCat:**
```
https://github.com/RevenueCat/purchases-ios.git
```
- Version: 4.31.0
- Add → RevenueCat seç → Add

**Firebase:**
```
https://github.com/firebase/firebase-ios-sdk.git
```
- Version: 10.19.0
- Add → FirebaseAnalytics + FirebaseCrashlytics seç → Add

Packages indirirken bekle (2-3 dakika)...

### Adım 8: API Key Yapılandırma

Terminal:
```bash
cd ~/workspaces/ai-ios-cleaner
cp Config.example.xcconfig Config.xcconfig
open Config.xcconfig
```

RevenueCat API key'inizi ekleyin.

### Adım 9: Config'i Xcode'a Bağla

1. Xcode'da proje ayarları → **Info** tab
2. **Configurations** bölümü
3. **Debug** → AI Cleaner sütunu → **Config** seç
4. **Release** → AI Cleaner sütunu → **Config** seç

**Config dosyasını Xcode'a eklemek için:**

**File → Add Files to "AI Cleaner"...**
- `~/workspaces/ai-ios-cleaner/Config.xcconfig` dosyasını seç
- ❌ "Copy items" KAPALI
- ❌ "Add to targets" KAPALI
- Add

### Adım 10: Build Settings Kontrol

**Build Settings** tab:
- Arama: `deployment`
- **iOS Deployment Target** = `16.0`

### Adım 11: BUILD!

1. Simulator seç: **iPhone 15 Pro**
2. **Product → Clean Build Folder** (⇧⌘K)
3. **Product → Build** (⌘B)

Build başarılı olmalı! ✅

### Adım 12: RUN!

**Product → Run** (⌘R)

---

## 🐛 Hala Sorun mu Var?

### "Cannot find module 'RevenueCat'" hatası

```bash
# Xcode'da:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Xcode hala crash ediyor

```bash
# Tüm Xcode'u sıfırla
rm -rf ~/Library/Developer/Xcode
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Xcode'u tekrar aç, tercihleri sıfırlamak isteyecek
```

### "File not found" hataları

Info.plist yolunu **ABSOLUTE PATH** olarak ver:
```
/Users/macbookpro/workspaces/ai-ios-cleaner/AI Cleaner/Resources/Info.plist
```

### Core Data modeli bulunamıyor

`AICleanerModel.xcdatamodeld` klasörünü manuel ekle:

1. **File → Add Files to "AI Cleaner"...**
2. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/Persistence/AICleanerModel.xcdatamodeld`
3. ❌ Copy KAPALI
4. ✅ Add to targets AÇIK
5. Add

---

## 🎉 Başarılı!

Eğer simulator'da uygulama çalıştıysa, **TEBRİKLER!**

Artık geliştirmeye başlayabilirsiniz! 🚀

---

## 📞 Hala Yardım mı Lazım?

Error mesajının tam ekran görüntüsünü atın, hemen çözerim!
