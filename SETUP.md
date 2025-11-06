# 🚀 AI Cleaner iOS - 2 Dakikada Xcode Projesi Kurulumu

Xcode projesini sıfırdan oluşturup tüm dosyaları ekleyelim. Çok basit!

## ⚡ Hızlı Kurulum (2 Dakika)

### Adım 1: Projeyi Klonlayın

```bash
cd ~/workspaces
git clone https://github.com/muratcankuruoffical/ai-ios-cleaner.git
cd ai-ios-cleaner
```

### Adım 2: Xcode'da Yeni Proje Oluşturun

1. **Xcode'u açın**
2. **File → New → Project** (⇧⌘N)
3. Şablonları seçin:
   - Platform: **iOS**
   - Template: **App**
   - **Next**

4. Proje bilgilerini girin:
   - **Product Name**: `AI Cleaner`
   - **Team**: Kendi team'inizi seçin
   - **Organization Identifier**: `com.aicleaner` (veya kendi domain'iniz)
   - **Bundle Identifier**: `com.aicleaner.AI-Cleaner`
   - **Interface**: ✅ **SwiftUI**
   - **Language**: ✅ **Swift**
   - **Storage**: ✅ **Core Data** (ÖNEMLİ - İşaretleyin!)
   - **Include Tests**: ❌ Kapalı (opsiyonel)
   - **Next**

5. Kaydetme konumu:
   - **Mevcut `ai-ios-cleaner` klasörünü seçin**
   - ⚠️ **"Create Git repository"** işaretini KALDIRIN (zaten Git var)
   - **Create**

### Adım 3: Xcode'un Oluşturduğu Dosyaları SİLİN

Xcode otomatik dosyalar oluşturdu, bunları silip bizim dosyalarımızı kullanacağız:

1. Sol panelde **AI Cleaner** grubu altında şunları **SİLİN** (Delete → Move to Trash):
   - `AI_CleanerApp.swift` (Xcode'un oluşturduğu)
   - `ContentView.swift` (Xcode'un oluşturduğu)
   - `AI_Cleaner.xcdatamodeld` (Xcode'un oluşturduğu - bizimki farklı isimde)
   - `Assets.xcassets` (Xcode'un boş olanı)
   - `Preview Content` klasörü (ihtiyacımız yok)

2. **Info.plist** dosyasını da silin (bizim hazırımız var)

### Adım 4: Gerçek Dosyaları Ekleyin

1. **File → Add Files to "AI Cleaner"...** (⌥⌘A)

2. `ai-ios-cleaner` klasöründen şu klasörleri seçin:
   - ✅ `AI Cleaner/App`
   - ✅ `AI Cleaner/Core`
   - ✅ `AI Cleaner/Features`
   - ✅ `AI Cleaner/Resources`

3. Alt kısımda şu ayarları yapın:
   - ✅ **"Copy items if needed"** - KAPAT (dosyalar zaten doğru yerde)
   - ✅ **"Create groups"** - Seçili olsun
   - ✅ **"Add to targets: AI Cleaner"** - Seçili olsun
   - **Add**

### Adım 5: Info.plist Ayarını Yapın

1. Sol panelde **AI Cleaner** projesine tıklayın (mavi simge en üstte)
2. **TARGETS** → **AI Cleaner** seçin
3. **Build Settings** tab'ına gidin
4. Arama kutusuna: `info.plist` yazın
5. **"Info.plist File"** satırını bulun
6. Değerini şuna çevirin: `AI Cleaner/Resources/Info.plist`

### Adım 6: Swift Package Dependencies Ekleyin

1. **File → Add Package Dependencies...**

2. İlk paket - **RevenueCat**:
   - URL: `https://github.com/RevenueCat/purchases-ios.git`
   - Dependency Rule: **Up to Next Major** → `4.31.0`
   - **Add Package**
   - Target'a ekle: **RevenueCat** seçin
   - **Add Package**

3. İkinci paket - **Firebase**:
   - URL: `https://github.com/firebase/firebase-ios-sdk.git`
   - Dependency Rule: **Up to Next Major** → `10.19.0`
   - **Add Package**
   - Target'a ekle: **FirebaseAnalytics** ve **FirebaseCrashlytics** seçin
   - **Add Package**

Package'ler indirilirken bekleyin (2-3 dakika)...

### Adım 7: API Key Yapılandırması

Terminal'de:

```bash
cd ~/workspaces/ai-ios-cleaner
cp Config.example.xcconfig Config.xcconfig
```

`Config.xcconfig` dosyasını açıp RevenueCat API key'inizi ekleyin:

```
REVENUECAT_API_KEY = sk_xxxxxxxxxxxxxxxxxx
```

**RevenueCat API Key nereden alınır:**
1. https://app.revenuecat.com/ → Hesap oluştur
2. Yeni proje oluştur
3. API Keys → iOS Public API Key kopyala

### Adım 8: Config Dosyasını Xcode'a Bağlayın

1. Sol panelde **AI Cleaner** projesine tıklayın (mavi simge)
2. **Info** tab'ına gidin
3. **Configurations** bölümünde:
   - **Debug** satırında **AI Cleaner** sütununa tıklayın → **Config** seçin
   - **Release** satırında **AI Cleaner** sütununa tıklayın → **Config** seçin

### Adım 9: Build Settings Düzeltmeleri

1. **Build Settings** tab'ına gidin
2. Arama: `deployment`
3. **iOS Deployment Target** → `16.0` yapın

### Adım 10: Build ve Run!

1. Simulator seçin: **iPhone 15 Pro** (veya herhangi bir iOS 16+)
2. **Product → Build** (⌘B)
3. **Product → Run** (⌘R)

---

## ✅ Checklist

- [ ] Xcode'da yeni proje oluşturdum (SwiftUI + Core Data)
- [ ] Xcode'un otomatik dosyalarını sildim
- [ ] Gerçek dosyaları ekledim (App, Core, Features, Resources)
- [ ] Info.plist yolunu ayarladım
- [ ] RevenueCat package'ini ekledim
- [ ] Firebase package'ini ekledim
- [ ] Config.xcconfig oluşturdum ve API key ekledim
- [ ] Config'i Debug/Release'e bağladım
- [ ] iOS Deployment Target 16.0 yaptım
- [ ] Build başarılı (⌘B)
- [ ] Simulator'da çalıştı (⌘R)

---

## 🐛 Sorun Giderme

### "Cannot find 'RevenueCat' in scope" hatası

```bash
# Xcode'da:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Build hatası: "Signing for requires a development team"

1. **Signing & Capabilities** tab'ına gidin
2. **Team**: Kendi Apple Developer hesabınızı seçin

### "Config.xcconfig file not found"

```bash
cd ~/workspaces/ai-ios-cleaner
cp Config.example.xcconfig Config.xcconfig
```

### Clean build gerekirse

```bash
# Xcode'da:
Product → Clean Build Folder (⇧⌘K)

# Ya da terminal'de:
rm -rf ~/Library/Developer/Xcode/DerivedData/AI_Cleaner-*
```

---

## 🎉 Tebrikler!

Xcode projeniz artık çalışıyor! Simulator'da test edebilir, gerçek cihaza yükleyebilir veya geliştirmeye devam edebilirsiniz.

**Sonraki adımlar:**
- Kendi app icon'unuzu ekleyin
- UI/UX iyileştirmeleri yapın
- TestFlight'a yükleyin
- App Store'a gönderin!
