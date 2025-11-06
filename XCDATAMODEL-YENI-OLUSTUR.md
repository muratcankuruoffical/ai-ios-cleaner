# 🎯 CORE DATA MODEL'İ YENİ OLUŞTUR (XCODE CRASH ÖNLEMİ)

## 🔴 SORUN

- Mevcut `.xcdatamodeld` dosyasını eklediğinizde Xcode kapanıyor
- Ama CoreDataStack.swift dosyası "AICleanerModel" adında bir model bekliyor (line 17)

## ✅ ÇÖZÜM

Eski .xcdatamodeld'yi eklemeyin, **YENİ BİR MODEL OLUŞTURUN** Xcode içinde!

---

## 📋 ADIM ADIM TALİMATLAR

### ÖNCE: Core Klasörünü Ekleyin (Model Hariç)

1. **Analytics** klasörünü ekle
2. **Extensions** klasörünü ekle
3. **Monetization** klasörünü ekle
4. **Services** klasörünü ekle
5. **Persistence** → Sadece `CoreDataStack.swift` + `Models` klasörünü ekle
   - ❌ .xcdatamodeld EKLEMEYİN!

---

## 🆕 YENİ CORE DATA MODEL OLUŞTUR

### Adım 1: Yeni Data Model Dosyası Oluştur

1. Xcode'da Project Navigator'da **Core/Persistence** klasörünü seçin
2. **File → New → File** (veya Command + N)
3. **iOS** sekmesinde **Data Model** seçin
4. Next
5. **Dosya adı:** `AICleanerModel` (tam olarak bu isim!)
6. **Kayıt yeri:** `AI Cleaner/Core/Persistence` klasörünün içinde
7. ✅ **Targets: AI Cleaner** seçili olmalı
8. Create

**SONUÇ:** Xcode kendi .xcdatamodeld dosyasını oluşturdu!

---

## 🏗️ ENTITY'LERİ EKLE

Şimdi boş model var, entity'leri ekleyelim:

### Adım 2: AssetFingerprint Entity'sini Oluştur

1. **AICleanerModel.xcdatamodeld** dosyasına tıklayın (Xcode visual editor açılır)
2. Altta **Add Entity** butonuna tıklayın
3. Entity adını **AssetFingerprint** yapın
4. Sağ tarafta **Data Model Inspector**'u açın (⌥⌘3)
5. **Class** bölümünde:
   - ✅ **Name:** `AssetFingerprint`
   - ✅ **Module:** `AI_Cleaner` (veya `Current Product Module`)
   - ✅ **Codegen:** **Manual/None** SEÇİN!

### Adım 3: AssetFingerprint Attribute'larını Ekle

Entity seçiliyken, **Attributes** bölümüne tıklayın, **+** ile ekleyin:

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| `assetLocalId` | String | NO | - |
| `blurScore` | Float | YES | 0.0 |
| `brightnessScore` | Float | YES | 0.0 |
| `id` | UUID | YES | - |
| `isScreenshot` | Boolean | YES | NO |
| `updatedAt` | Date | YES | - |
| `vectorData` | Binary Data | YES | - |
| `vectorElementCount` | Integer 32 | YES | 0 |

**HER BİRİNİ TEK TEK EKLEYİN!**

### Adım 4: AssetFingerprint Uniqueness Constraint

1. Entity seçili
2. **Constraints** bölümüne gidin (altta)
3. **+** tıkla
4. Yeni constraint'e tıkla
5. **assetLocalId** seçin
6. Bu, aynı asset'in iki kere eklenmesini önler

### Adım 5: ScanSession Entity'sini Oluştur

1. Tekrar **Add Entity**
2. Adı: **ScanSession**
3. Data Model Inspector:
   - ✅ **Name:** `ScanSession`
   - ✅ **Module:** `Current Product Module`
   - ✅ **Codegen:** **Manual/None**

### Adım 6: ScanSession Attribute'larını Ekle

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| `deletedCount` | Integer 32 | YES | 0 |
| `finishedAt` | Date | YES | - |
| `freedBytes` | Integer 64 | YES | 0 |
| `id` | UUID | YES | - |
| `processedCount` | Integer 32 | YES | 0 |
| `startedAt` | Date | YES | - |

### Adım 7: KAYDET!

**Command + S** → Model kayıt edildi!

---

## ✅ MODEL HAZIR!

Artık:
- ✅ AICleanerModel.xcdatamodeld Xcode içinde oluştu (crash yok!)
- ✅ AssetFingerprint entity tanımlı
- ✅ ScanSession entity tanımlı
- ✅ Manual codegen (Swift files'lar zaten var)
- ✅ CoreDataStack.swift çalışacak!

---

## 🔍 KONTROL

Project Navigator'da şöyle görünmeli:

```
AI Cleaner/
  Core/
    Persistence/
      AICleanerModel.xcdatamodeld     ← ✅ YENİ OLUŞTURULDU!
      CoreDataStack.swift
      Models/
        AssetFingerprint+CoreDataClass.swift
        AssetFingerprint+CoreDataProperties.swift
        ScanSession+CoreDataClass.swift
        ScanSession+CoreDataProperties.swift
```

---

## 🧪 TEST

Build yapın: **Command + B**

Hata almamalısınız! 🎉

---

## 💡 NEDEN BU ÇALIŞIR?

1. **Xcode Kendi Dosyasını Seviyor:**
   - Xcode içinde oluşturulan .xcdatamodeld crash yapmaz
   - Dışarıdan eklenen .xcdatamodeld crash yapabilir

2. **Manual Codegen:**
   - Entity'leri tanımladık ama codegen kapalı
   - Xcode otomatik Swift files oluşturmaz
   - Bizim manuel Swift files'lar kullanılır

3. **CoreDataStack Mutlu:**
   - `NSPersistentContainer(name: "AICleanerModel")` → Model bulur
   - Manuel Swift files ile entity'leri yükler
   - Her şey çalışır!

---

## 🚨 ÖNEMLİ NOTLAR

1. **Codegen Mutlaka Manual/None Olmalı!**
   - Eğer Category veya Class Definition seçerseniz
   - Xcode otomatik Swift files oluşturur
   - Bizim manuel files'larla çakışır
   - Build error: "duplicate symbol"

2. **Entity İsimleri Tam Eşleşmeli:**
   - ✅ "AssetFingerprint" (tam bu şekilde)
   - ✅ "ScanSession" (tam bu şekilde)
   - ❌ "assetFingerprint" (yanlış)
   - ❌ "Scan Session" (yanlış)

3. **Module Ayarı:**
   - "Current Product Module" seçin
   - Bu, Swift files'ların aynı module'de olmasını sağlar

---

## 🆘 SORUN GİDERME

### Build Error: "Duplicate symbol for architecture arm64"

**Çözüm:** Codegen Manual/None değil. Her entity için:
1. Entity'ye tıkla
2. Data Model Inspector aç
3. Codegen → Manual/None

### Build Error: "Cannot find type 'AssetFingerprint' in scope"

**Çözüm:** Models klasöründeki Swift files eklenmedmememiş:
- Add Files to Project
- `Core/Persistence/Models/` klasörünü ekle

### Runtime Error: "The model used to open the store is incompatible"

**Çözüm:** Entity attribute'ları yanlış. Yukarıdaki tablolarla karşılaştır.

---

## 🎯 ÖZET

1. ❌ Eski .xcdatamodeld'yi eklemeyin (crash yapar)
2. ✅ Xcode'da yeni .xcdatamodeld oluşturun
3. ✅ Entity'leri manuel ekleyin
4. ✅ Codegen → Manual/None
5. ✅ Build → Çalışır! 🚀

Bu yöntem %100 güvenli ve Xcode crash yapmaz! 💪
