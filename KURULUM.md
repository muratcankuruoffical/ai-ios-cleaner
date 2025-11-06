# 🚀 AI Cleaner iOS - Kurulum Rehberi

AI Cleaner iOS uygulamasını Xcode'da çalıştırmak için adım adım rehber.

## ⚡ Hızlı Başlangıç

```bash
# 1. Projeyi klonlayın
git clone https://github.com/muratcankuruoffical/ai-ios-cleaner.git
cd ai-ios-cleaner

# 2. API key'leri yapılandırın
cp Config.example.xcconfig Config.xcconfig
# Config.xcconfig dosyasını açıp API key'lerinizi ekleyin

# 3. Xcode'da açın
open "AI Cleaner.xcodeproj"

# 4. Build ve Run! (⌘+R)
```

## 📋 Gereksinimler

- **macOS**: Ventura (13.0) veya üstü
- **Xcode**: 15.0 veya üstü
- **Swift**: 5.9+
- **iOS Deployment Target**: 16.0+
- **Developer Account**: Gerçek cihazda test için Apple Developer hesabı

## 🔧 Detaylı Kurulum

### Adım 1: Projeyi Klonlayın

```bash
git clone https://github.com/muratcankuruoffical/ai-ios-cleaner.git
cd ai-ios-cleaner
```

### Adım 2: API Key Yapılandırması

#### RevenueCat API Key (Zorunlu)

1. **RevenueCat hesabı oluşturun**: https://app.revenuecat.com/
2. Yeni bir proje oluşturun
3. **API Keys** bölümünden iOS Public API Key'inizi kopyalayın
4. Config dosyasını oluşturun:

```bash
cp Config.example.xcconfig Config.xcconfig
```

5. `Config.xcconfig` dosyasını açıp API key'inizi ekleyin:

```
REVENUECAT_API_KEY = sk_xxxxxxxxxxxxxxxxxx
```

#### Firebase (Opsiyonel - Analytics için)

1. Firebase Console'da proje oluşturun
2. iOS uygulaması ekleyin (Bundle ID: `com.aicleaner.AI-Cleaner`)
3. `GoogleService-Info.plist` dosyasını indirin
4. Dosyayı `AI Cleaner/Resources/` klasörüne kopyalayın

### Adım 3: Xcode'da Açın

```bash
open "AI Cleaner.xcodeproj"
```

Alternatif olarak Finder'dan `AI Cleaner.xcodeproj` dosyasına çift tıklayın.

### Adım 4: Swift Package Dependencies

Xcode projeyi açtığında otomatik olarak şu paketleri indirecek:

- ✅ **RevenueCat** (4.31.0+) - Abonelik yönetimi
- ✅ **Firebase iOS SDK** (10.19.0+) - Analytics ve Crashlytics

İlk açılışta birkaç dakika sürebilir. Xcode ekranının üst kısmında indirme durumunu görebilirsiniz.

**Eğer otomatik indirme başlamazsa:**
1. Xcode'da **File → Packages → Resolve Package Versions** seçin
2. Bekleyin...

### Adım 5: Proje Ayarları

#### a) Team Seçimi (Zorunlu)

1. Sol panelden **AI Cleaner** projesini seçin (mavi simge)
2. **TARGETS** → **AI Cleaner** seçin
3. **Signing & Capabilities** tab'ına gidin
4. **Team**: Kendi Apple Developer team'inizi seçin

#### b) Bundle Identifier (Opsiyonel)

Varsayılan: `com.aicleaner.AI-Cleaner`

Değiştirmek isterseniz:
1. **General** tab'ında
2. **Bundle Identifier** alanını düzenleyin

### Adım 6: Build ve Run!

1. **Simulator seçin**: Xcode üst barında iPhone 15 Pro (veya herhangi bir iOS 16+ simulator)
2. **Build**: ⌘+B (veya Product → Build)
3. **Run**: ⌘+R (veya Play butonu)

## 📱 Gerçek Cihazda Test

### Gereksinimler:
- Apple Developer hesabı (Free tier yeterli)
- USB ile bağlı iOS cihaz (iOS 16+)

### Adımlar:
1. iPhone'u Mac'e bağlayın
2. iPhone'da **Settings → Privacy & Security → Developer Mode** açın
3. Xcode'da cihazınızı seçin (simulator yerine)
4. İlk çalıştırmada iPhone'da **Settings → General → VPN & Device Management** → Uygulamanıza güvenin
5. Run! (⌘+R)

## 🎨 Uygulama İkonu Ekleme

Şu anda placeholder ikon var. Kendi ikonunuzu eklemek için:

1. Xcode'da **AI Cleaner/Resources/Assets.xcassets** açın
2. **AppIcon** seçin
3. 1024x1024 PNG dosyanızı sürükleyip bırakın

Xcode otomatik olarak tüm boyutları oluşturacaktır.

## ⚙️ Proje Yapısı

```
AI Cleaner/
├── App/                          # Uygulama entry point
│   ├── AI_CleanerApp.swift      # Main app file
│   └── AppRouter.swift          # Navigation router
├── Core/                         # Core functionality
│   ├── Analytics/               # Firebase Analytics
│   ├── Extensions/              # Swift extensions
│   ├── Monetization/            # RevenueCat integration
│   ├── Persistence/             # Core Data stack
│   │   ├── AICleanerModel.xcdatamodeld
│   │   └── Models/              # Core Data entities
│   └── Services/                # Business logic
│       ├── VisionService.swift  # Image feature extraction
│       ├── BlurDetector.swift   # Blur detection
│       ├── DarknessDetector.swift
│       ├── SimilarityService.swift
│       └── ...
├── Features/                     # UI Features
│   ├── Duplicates/              # Swipe deck for duplicates
│   ├── Onboarding/              # First-time user flow
│   ├── Paywall/                 # Subscription paywall
│   ├── Reports/                 # Dashboard
│   ├── Scanner/                 # Photo scanning
│   ├── Settings/                # App settings
│   └── SmartAlbums/             # Categorized albums
└── Resources/
    ├── Assets.xcassets/         # Images, colors
    └── Info.plist              # App configuration

AI Cleaner.xcodeproj/           # Xcode project
Config.xcconfig                  # API keys (git ignored)
```

## 🐛 Sorun Giderme

### "No such module 'RevenueCat'" hatası

**Çözüm:**
```bash
# Xcode'da:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Build hatası: "Command PhaseScriptExecution failed"

**Çözüm:**
1. Xcode → **Preferences** → **Locations**
2. **Command Line Tools** seçili olduğundan emin olun

### Simulator açılmıyor

**Çözüm:**
```bash
# Terminal'de:
sudo xcode-select --reset
sudo xcodebuild -runFirstLaunch
```

### Core Data hatası

**Çözüm:**
1. Simulator'ı sıfırlayın: **Device → Erase All Content and Settings**
2. Clean Build Folder: ⌘+Shift+K
3. Tekrar build edin: ⌘+B

### "Failed to verify bitcode" hatası

**Çözüm:**
1. **Build Settings** → **Enable Bitcode** → **No** yapın

### Config.xcconfig bulunamıyor

**Hata**: `Config.xcconfig dosyası bulunamadı`

**Çözüm:**
```bash
cp Config.example.xcconfig Config.xcconfig
# Sonra dosyayı düzenleyin
```

## 📊 Build Konfigürasyonları

### Debug (Geliştirme)
- Optimizasyon: Yok
- Debug sembolleri: Var
- RevenueCat: Debug modu
- Firebase: Test projesi

### Release (Production)
- Optimizasyon: Tam
- Debug sembolleri: Yok
- RevenueCat: Production
- Firebase: Live projesi

Debug modunu kullanın: **Product → Scheme → Edit Scheme** → **Run** → **Build Configuration** → **Debug**

## 🔑 Permissions

Uygulama şu izinleri kullanıyor:

- ✅ **Photos Library**: Fotoğraf analizi için (Info.plist'te tanımlı)
- ✅ **Face ID / Touch ID**: Pro abonelik doğrulama (opsiyonel)

Simulator'da fotoğraf yüklemek için:
1. Safari'den bir resmi indirin
2. Photos app'te göreceksiniz
3. AI Cleaner'ı çalıştırın

## 🚀 İlk Çalıştırma Checklist

- [ ] Projeyi klonladım
- [ ] `Config.xcconfig` oluşturdum ve API key ekledim
- [ ] Xcode'da açtım
- [ ] Swift packages indirildi
- [ ] Team seçtim (Signing & Capabilities)
- [ ] Simulator/Device seçtim
- [ ] Build başarılı (⌘+B)
- [ ] Run başarılı (⌘+R)
- [ ] Onboarding ekranını gördüm

## 📞 Yardım

Sorun mu yaşıyorsunuz?

1. **GitHub Issues**: https://github.com/muratcankuruoffical/ai-ios-cleaner/issues
2. **README.md**: Proje dökümantasyonunu okuyun
3. **SECURITY_SETUP.md**: API key kurulum rehberi

## 🎉 Tebrikler!

Artık AI Cleaner iOS uygulaması cihazınızda çalışıyor!

**Sonraki adımlar:**
- Kendi fotoğraflarınızla test edin
- UI/UX iyileştirmeleri yapın
- Kendi app icon'unuzu ekleyin
- TestFlight'a yükleyin
- App Store'a gönderin!

---

**Not**: Bu bir MVP (Minimum Viable Product) projesidir. Production'a göndermeden önce:
- Kapsamlı testler yapın
- Privacy policy ekleyin
- App Store screenshots hazırlayın
- RevenueCat production key'i kullanın
