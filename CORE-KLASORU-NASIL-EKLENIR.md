# 🔴 CORE KLASÖRÜ NASIL EKLENİR

**SORUN:** Core klasörünü toptan eklediğinizde Xcode kapanıyor.

**SEBEP:** İçindeki `AICleanerModel.xcdatamodeld` (Core Data model) dosyası Xcode'u crash yapıyor.

**ÇÖZÜM:** Core klasörünü **ALT KLASÖRLERE** bölerek ekleyin!

---

## 📋 ADIM ADIM TALİMATLAR

### Adım 1: Analytics Klasörünü Ekle
1. Xcode'da projeye sağ tıklayın
2. "Add Files to 'AI Cleaner'..."
3. Şu klasöre gidin: `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/`
4. **Sadece Analytics klasörünü** seçin
5. ⚠️ **"Copy items if needed" KAPALI** olmalı
6. ✅ **"Create groups" SEÇİLİ** olmalı
7. Add'e basın

### Adım 2: Extensions Klasörünü Ekle
1. Tekrar "Add Files to 'AI Cleaner'..."
2. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/`
3. **Sadece Extensions klasörünü** seçin
4. ⚠️ "Copy items if needed" KAPALI
5. ✅ "Create groups" SEÇİLİ
6. Add'e basın

### Adım 3: Monetization Klasörünü Ekle
1. Tekrar "Add Files to 'AI Cleaner'..."
2. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/`
3. **Sadece Monetization klasörünü** seçin
4. ⚠️ "Copy items if needed" KAPALI
5. ✅ "Create groups" SEÇİLİ
6. Add'e basın

### Adım 4: Services Klasörünü Ekle
1. Tekrar "Add Files to 'AI Cleaner'..."
2. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/`
3. **Sadece Services klasörünü** seçin
4. ⚠️ "Copy items if needed" KAPALI
5. ✅ "Create groups" SEÇİLİ
6. Add'e basın

---

## 🔥 ADIM 5: PERSISTENCE KLASÖRÜ (DİKKATLİ!)

Persistence klasöründe Core Data model var, bu yüzden **iki parçada** ekleyeceğiz:

### 5A: Önce Swift Dosyalarını Ekle

1. "Add Files to 'AI Cleaner'..."
2. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/Persistence/`
3. **Sadece şu dosyaları seçin:**
   - ✅ `CoreDataStack.swift`
   - ✅ `Models` klasörü (içindeki 4 Swift dosyası)
   - ❌ `AICleanerModel.xcdatamodeld` **SEÇMEYİN!**
4. ⚠️ "Copy items if needed" KAPALI
5. Add'e basın

**Kontrol:** Project Navigator'da Core/Persistence altında CoreDataStack.swift ve Models klasörünü görmelisiniz.

### 5B: Şimdi Core Data Model'i Ekle

1. **Xcode'u KAYDET:** Command + S
2. **Xcode'u KAPATIN:** Command + Q
3. **5 saniye bekleyin**
4. Xcode'u **YENİDEN AÇIN**
5. Projenizi açın
6. "Add Files to 'AI Cleaner'..."
7. `~/workspaces/ai-ios-cleaner/AI Cleaner/Core/Persistence/`
8. **Sadece `AICleanerModel.xcdatamodeld`** seçin
9. ⚠️ "Copy items if needed" KAPALI
10. ✅ "Create groups" SEÇİLİ
11. Add'e basın

---

## ✅ KONTROL LİSTESİ

Xcode Project Navigator'da Core klasörü şöyle görünmeli:

```
AI Cleaner/
  Core/
    Analytics/
      AnalyticsManager.swift
    Extensions/
      Color+Extensions.swift
      Date+Extensions.swift
      View+Extensions.swift
    Monetization/
      RevenueCatManager.swift
    Persistence/
      AICleanerModel.xcdatamodeld
      CoreDataStack.swift
      Models/
        AssetFingerprint+CoreDataClass.swift
        AssetFingerprint+CoreDataProperties.swift
        ScanSession+CoreDataClass.swift
        ScanSession+CoreDataProperties.swift
    Services/
      BlurDetector.swift
      DarknessDetector.swift
      PhotoLibraryService.swift
      ScreenshotDetector.swift
      SimilarityService.swift
      VideoAnalyzer.swift
      VisionService.swift
```

---

## 🚨 SORUN GİDERME

### Xcode Hala Kapanıyorsa:

1. **Xcode'u Kapat**
2. Terminal'de:
   ```bash
   cd ~/workspaces/ai-ios-cleaner
   ./cleanup.sh
   ```
3. **Mac'i restart et**
4. Bu guide'ı baştan başla

### "Duplicate Symbol" Hatası:

Eğer build sırasında "duplicate" hatası alırsanız:
1. Core Data model'e tıklayın (.xcdatamodeld)
2. Sağ tarafta "Data Model Inspector" açın
3. Her entity için (AssetFingerprint, ScanSession):
   - "Codegen" → **Manual/None** olarak ayarlayın

---

## 💡 NEDEN BU YÖNTEM?

- Core Data model dosyası (.xcdatamodeld) özel bir Xcode formatıdır
- Toptan eklenince Xcode bunu parse ederken crash yapabilir
- Alt klasörlere böldüğümüzde Xcode her dosyayı tek tek işler
- Core Data model'i en son eklediğimizde diğer dosyalar zaten proje içinde olduğu için daha güvenli

---

**HATIRLATMA:** Her "Add Files" işleminden sonra:
- ⚠️ "Copy items if needed" KAPALI
- ✅ "Create groups" SEÇİLİ
- ✅ "Add to targets: AI Cleaner" SEÇİLİ

Başarılar! 🚀
