# AI Cleaner iOS — Claude Code için A‑Z MVP Planı (Swift + On‑Device AI)

> **Amaç:** iOS’ta *tamamen cihaz üzerinde* çalışan, fotoğraf kütüphanesini akıllıca analiz eden, benzer/kalitesiz görüntüleri tespit eden ve **Tinder benzeri kaydır‑sil** akışıyla temizleme deneyimi sunan bir uygulamayı **10 gün** içinde çıkartmak.
>
> **Kapsam:**
>
> 1. Akıllı Fotoğraf Analizi
> 2. Medya ve Dosya Yönetimi
> 3. Smart Albums / Görsel Raporlama
> 4. Gizlilik & Güvenlik Özellikleri
> 5. Monetizasyon ve Premium Özellikler (RevenueCat)
> 6. Görsel & Deneyim Katmanları *(sesli bildirim yok)*
>    **Not:** “AI Asistan” (8) **bu sürümde yok**.

---

## 0) Proje Yapısı ve Teknolojiler

**Dil & UI**: Swift 5.10+, **SwiftUI**
**iOS Sürümü**: iOS 16+ (PhotoKit, Vision, Core ML, vImage için iyi denge)
**AI/ML (On‑Device)**: Vision (`VNGenerateImageFeaturePrintRequest`), CoreImage, Accelerate/vImage
**Veri Saklama**: Core Data (veya SQLite) — *feature vector cache* + tarama sonuçları
**Analitik & Crash**: Firebase (Analytics, Crashlytics)
**Ödeme**: **RevenueCat** (abone yönetimi + paywall)
**İzinler**: `NSPhotoLibraryUsageDescription` (gerekirse `NSPhotoLibraryAddUsageDescription`)
**Gizlilik**: Tamamen cihaz‑içi; buluta fotoğraf yüklenmez

**Paket Yönetimi (SPM)**:

* RevenueCat (`https://github.com/RevenueCat/purchases-ios`)
* Firebase SPM (Analytics + Crashlytics)

**Dizin Yapısı (öneri)**:

```
AI Cleaner/
  ├─ App/
  │   ├─ AI_CleanerApp.swift
  │   └─ AppRouter.swift
  ├─ Core/
  │   ├─ DI/
  │   ├─ Extensions/
  │   ├─ Services/ (PhotoLibraryService, VisionService, SimilarityService, BlurDetector, VideoAnalyzer)
  │   ├─ Persistence/ (CoreDataStack, Models)
  │   ├─ Monetization/ (RevenueCatManager, PaywallView)
  │   └─ Analytics/ (AnalyticsManager)
  ├─ Features/
  │   ├─ Onboarding/
  │   ├─ Scanner/ (ScanCoordinator, ScanProgressView)
  │   ├─ Duplicates/
  │   │   ├─ SwipeDeckView (Tinder‑like)
  │   │   └─ GroupReviewView
  │   ├─ SmartAlbums/
  │   ├─ Reports/
  │   ├─ Settings/
  │   └─ Paywall/
  └─ Resources/
      ├─ Assets.xcassets
      └─ Info.plist
```

---

## 1) Akıllı Fotoğraf Analizi

**Hedef:** Fotoğrafları *cihaz üzerinde* analiz ederek:

* **Benzer gruplar** (near‑duplicates)
* **Bulanık / düşük kaliteli** fotoğraflar
* **Karanlık / düşük kontrast** çekimler
* **Screenshot** tespiti

**Teknik Tasarım:**

* `PhotoLibraryService`: `PHAsset` ile fotoğrafları çeker, `PHCachingImageManager` ile thumbnail & analysis boyutunda bitmap sağlar.
* `VisionService`: `VNGenerateImageFeaturePrintRequest` ile **feature vector** çıkarır. Sonuçlar **Core Data**’da cache’lenir (`FeaturePrintEntity`: assetId, vectorBlob, updatedAt, fingerprintHash).
* `SimilarityService`:

  * Vektörler arası **cosine distance** / **L2** ile yakınlık ölçer.
  * Basit **clustering**: threshold + union‑find / single‑linkage ile grup oluşturma.
* `BlurDetector`: vImage/CI ile **Laplacian variance** tabanlı skor.
* `DarknessDetector`: parlaklık histogramı + ortalama luminance eşiği.
* `ScreenshotDetector`: çözünürlük oranı + EXIF `software` ipucu + `UTType` kontrolü.

**Akış:**

1. Kullanıcı izin verir → tarama başlar.
2. Cache miss olan fotolar için feature print hesapla → Core Data’ya yaz.
3. Toplanan vektörlerle benzerlik grafı kur → gruplar.
4. Bulanık/karanlık/screenshot etiketleri ekle.
5. Sonuçlar `ScanResults` olarak UI’a akıtılır.

**Performans İpuçları:**

* Batch halinde, **background queue**’larda analiz yap.
* `PHImageRequestOptions.isSynchronous = false`, uygun `deliveryMode` kullan.
* Büyük kütüphanelerde taramayı sayfalayıp **progress** göster.
* Vektör boyutu küçük olduğundan Core Data blob’ları yönetilebilir.

---

## 2) Medya ve Dosya Yönetimi

**Hedef:** Kullanıcıya alan kazandırmak için büyük dosyaları ve benzer videoları tespit etmek, basit optimizasyon aksiyonları önermek.

**Özellikler:**

* **Büyük Video Bulucu:** `PHAssetMediaType.video` + `fileSize` (via `PHAssetResource`) > eşiğe göre listele (örn. 200MB+).
* **Benzer Video (Basit):** Thumbnail hash + süre/çözünürlük yakınlığı ile kaba gruplama. (İleri sürüme audio fingerprint eklenebilir.)
* **Fotoğraf Optimize (Opsiyonel V1.1):** 4K → 1080p yeniden örnekleme (kopyasını oluşturup orijinali isteğe bağlı silme). *V1.0’da yalnızca öneri/analiz.*

**Silme & Değişiklikler:**

* `PHPhotoLibrary.shared().performChanges` ile silme/ taşıma.
* Kullanıcıdan **açık onay**: Swipe akışı + “Geri Al”/“Son Silinenler” notu.

---

## 3) Smart Albums / Görsel Raporlama

**Smart Albums:**

* **Benzerler**, **Bulanıklar**, **Karanlıklar**, **Screenshot’lar**, **Büyük Videolar** gibi sanal koleksiyonlar.
* Kullanıcı bu albümlerde card‑stack veya grid görünümünde gezebilir.

**Raporlama (Dashboard):**

* “Bu hafta X fotoğraf tarandı, Y MB temizlendi.”
* Kümeler bazında **önerilen kazanç** (örn. “Şu gruptan 6/8’ini silersen +450MB”).
* Basit grafikler: Çubuk/çizgi (SwiftUI Charts, iOS 16+).

---

## 5) Gizlilik & Güvenlik Özellikleri

* **Tamamen On‑Device:** Hiçbir fotoğraf/videonun cihaz dışına çıkmayacağını **onboarding**’de açıkla.
* **İzinler:** `NSPhotoLibraryUsageDescription` (metin: “Analiz ve temizlik için fotoğraflarınıza erişmemiz gerekiyor.”).
* **Silme Güvenliği:** iOS’in “Son Silinenler” klasörü mantığını kullanıcıya hatırlat (geri alma olanağı).
* **Gizli Albüm Önerisi:** Kimlik/kart gibi hassas görselleri tespit edersen (ileriki sürüm), “Gizli Albüm”e taşıma öner.
* **Gizlilik Politikası:** App Store için basit bir metin: “Veriler cihazda işlenir, 3. tarafla paylaşılmaz.” (Firebase analytics dışında — anonim)

---

## 6) Monetizasyon ve Premium (RevenueCat)

**Paketler:**

* **Free**: Günde 1 tarama, günde 1 “silme oturumu”, günlük 50 swipe limiti.
* **Premium Monthly**: Sınırsız tarama + sınırsız swipe + Büyük Video bulucu + Raporlama detayları.
* **Premium Yearly**: Aylığa göre %40 indirim.
* **Lifetime** (opsiyonel): Tek sefer.

**RevenueCat Yapılandırma:**

* **App**: `ai-cleaner-ios`
* **Entitlements**: `pro`
* **Offerings**: `cleaner_default`

  * **Packages**:

    * `monthly` → `com.acme.cleaner.pro.monthly`
    * `annual` → `com.acme.cleaner.pro.annual`
    * `lifetime` → `com.acme.cleaner.pro.lifetime` (opsiyonel)

**Paywall & Akış:**

* Tarama bitiminde “+2GB potansiyel kazanç” benzeri kişisel teklif → Paywall.
* Ayarlar ekranında abonelik yönetimi (RevenueCat müşteri bilgi ekranı).
* **Deneme**: 3 gün free trial (opsiyonel; yerel pazar fiyatına göre ayarla).

---

## 7) Görsel & Deneyim Katmanları (Sesli Bildirim Yok)

**Tema:** Minimal, temiz, rahat gri‑beyaz tonlar + vurguda birincil renk.
**Bileşenler:**

* **Swipe Deck (Tinder‑like):** Benzer grup içinde kartları sağa (sil), sola (tut) kaydır.

  * Haptic feedback (light/rigid).
  * Kart üzerinde pre‑label: “Sil” / “Tut”.
* **Grid İnceleme:** Kart destesi öncesi grubu *grid* olarak hızlı gör.
* **İlerleme Çubuğu:** Tarama ilerlemesi + kalan süre tahmini.
* **Onboarding:** 3 ekran — gizlilik, izin izahı, değer önerisi.
* **Boş Durum Ekranları:** İlham verici kısa metin + “Şimdi Tara” CTA.

**Erişilebilirlik:** Dynamic Type, VoiceOver label’ları, yüksek kontrast uyumu.

---

## UI Akış Haritası

1. **Launch → Onboarding** (gizlilik, izin açıklaması)
2. **İzin İsteği → Ana Ekran (Dashboard)**

   * “Taramaya Başla”
   * Son raporlar, potansiyel kazanç kutucukları
3. **Tarama İlerlemesi** (iptal/arka plana alma)
4. **Sonuçlar:**

   * **Smart Albums**: Benzerler / Bulanık / Karanlık / Screenshots / Büyük Videolar
   * Her koleksiyonda **GroupReview** → **Swipe Deck**
5. **Swipe Deck:**

   * Sağ: **Sil** kuyruğuna ekle
   * Sol: **Tut** kuyruğuna ekle
   * “Seçilenleri Sil” CTA (PHPhotoLibrary.performChanges)
6. **Paywall Prompt** (Free limit aşıldı → RevenueCat)
7. **Ayarlar:** Abonelik yönetimi, gizlilik politikası, analytics opt‑out, tema

---

## Örnek Veri Modelleri (Core Data)

* `AssetFingerprint`

  * `id: UUID`
  * `assetLocalId: String`
  * `vector: Data` (float32 dizi)
  * `blurScore: Float`
  * `brightnessScore: Float`
  * `isScreenshot: Bool`
  * `updatedAt: Date`

* `ScanSession`

  * `id: UUID`
  * `startedAt: Date`
  * `finishedAt: Date?`
  * `processedCount: Int`
  * `deletedCount: Int`
  * `freedBytes: Int64`

---

## Önemli Kod Parçaları (İskelet)

**Fotoğraf Erişimi (izin + fetch):**

```swift
import Photos

final class PhotoLibraryService {
    func requestAuth(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    func fetchImages() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: options)
    }
}
```

**Feature Print Çıkartma:**

```swift
import Vision
import UIKit

final class VisionService {
    private let request = VNGenerateImageFeaturePrintRequest()

    func featurePrint(for image: CGImage) throws -> VNFeaturePrintObservation {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        return request.results?.first as! VNFeaturePrintObservation
    }

    func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) throws -> Float {
        var d: Float = 0
        try a.computeDistance(&d, to: b)
        return d
    }
}
```

**Silme İşlemi:**

```swift
func delete(assets: [PHAsset], completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.deleteAssets(assets as NSArray)
    }) { success, _ in
        DispatchQueue.main.async { completion(success) }
    }
}
```

**Swipe Deck (SwiftUI İskeleti):**

```swift
struct SwipeCard: View {
    let asset: PHAsset
    @State private var offset: CGSize = .zero
    var onKeep: () -> Void
    var onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            AssetImageView(asset: asset)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
            if offset.width > 60 { Label("Sil", systemImage: "trash") }
            if offset.width < -60 { Label("Tut", systemImage: "checkmark") }
        }
        .gesture(
            DragGesture()
                .onChanged { offset = $0.translation }
                .onEnded { value in
                    if value.translation.width > 120 { onDelete() }
                    else if value.translation.width < -120 { onKeep() }
                    else { withAnimation { offset = .zero } }
                }
        )
        .offset(x: offset.width, y: 0)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .animation(.spring(), value: offset)
    }
}
```

---

## Analytics & Crash

* **Firebase Analytics**: Tarama başlatıldı, tarama bitti, paywall gösterildi, satın alma başarılı vb. event’ler.
* **Crashlytics**: Çökmeleri yakala.
* **Opt‑out**: Ayarlarda basit bir toggle (Analytics’i kapat) — kullanıcı güveni.

---

## Test Planı

* **Kütüphane Boyutu Senaryoları**: 500, 5.000, 50.000 fotoğraflı test.
* **Eşik Değerleri**: Benzerlik threshold, blur threshold A/B.
* **Performans**: İlk tarama süresi, incremental tarama (yalnızca yeni/ değişen varlıklar).
* **İzin Senaryoları**: Full / Limited Photo Access.
* **Silme Güvenliği**: Yanlış silme → Son Silinenler uyarması, geri bildirim akışı.

---

## App Store Hazırlıkları

* **App Privacy**: Cihaz‑içi işleme, kişisel veriler aktarılmıyor; yalnızca anonim kullanım analitiği.
* **Screenshots**: Onboarding, Tarama, Smart Albums, Swipe Deck, Raporlar.
* **Açıklama**: “On‑device AI ile güvenli temizlik. Fotoğraflarınız cihazdan çıkmaz.”
* **Fiyatlandırma**: TR fiyat katmanları → Monthly/Yearly/Lifetime ayarla.
* **Review Notları**: Fotoğraf izin kullanım amacı, RevenueCat entegrasyonu, deneme süresi.

---

## 10 Günlük Geliştirme Planı

**Gün 1**: Proje iskeleti, SPM entegrasyonları (RevenueCat, Firebase), Core Data şeması, izin akışı
**Gün 2**: Photo fetch + caching image manager + ilk feature print hesaplama
**Gün 3**: Benzerlik ölçümü + grup oluşturma (threshold + basit clustering)
**Gün 4**: Blur & darkness dedektörleri, screenshot tespiti
**Gün 5**: **Swipe Deck** ilk sürüm + silme kuyruğu + PHPhotoLibrary changes
**Gün 6**: Smart Albums ekranları + grid → group review → swipe akışı
**Gün 7**: Dashboard/Raporlar + Charts
**Gün 8**: Paywall + RevenueCat (offerings) + free limit mantığı
**Gün 9**: Analytics/Crash + performans optimizasyonu + boş durum ekranları
**Gün 10**: QA, Test senaryoları, App Store metadata, ikon/screenshot

---

## Info.plist Örnek Anahtarlar

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Fotoğraflarınızı analiz edip temizleyebilmek için erişime ihtiyacımız var. Veriler cihazı terk etmez.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Düzenlenen görselleri kaydetmek için izne ihtiyacımız olabilir.</string>
```

---

## RevenueCat Entegrasyon İskeleti

```swift
import Purchases

@main
struct AI_CleanerApp: App {
  init() {
    Purchases.configure(withAPIKey: "REVENUECAT_PUBLIC_SDK_KEY")
  }
  var body: some Scene { WindowGroup { RootView() } }
}
```

**Paywall Açma Koşulu (örnek):**

```swift
if usage.freeSwipesToday >= 50 && !entitlements.pro {
    showPaywall = true
}
```

---

## Riskler & Alternatifler

* **Büyük Kütüphaneler**: İlk tarama süresi uzun olabilir → incremental tarama + önbellek.
* **Performans**: Vektör karşılaştırması O(n²) büyüyebilir → locality‑sensitive hashing (LSH) veya yaklaşık en yakın komşu (ANN) ileriki sürüm.
* **Hatalı Pozitif/Negatif**: Eşik ayarları için kullanıcı geri bildirim döngüsü + “yanlış önerileri sakla” opsiyonu.

---

## Sonraki Sürümler (V1.1+)

* Video optimizasyonu (yeniden kodlama),
* Daha gelişmiş ANN kütüphaneleri (cihaz‑içi),
* Gizli Albüm otomasyonu,
* Çok dilli yerelleştirme (TR, EN, RU),
* Widget & App Shortcuts.

---

**Hazır mısın Claude?**
Bu dokümanı takip ederek proje iskeletini oluştur, bağımlılıkları ekle, çekirdek servisleri (PhotoLibraryService, VisionService, SimilarityService, BlurDetector) yaz, ardından UI akışlarını (Onboarding → Scan → Smart Albums → Swipe Deck → Paywall) adım adım tamamla.

> Not: Her modül için birim testlerini ve performans ölçümlerini eklemeyi unutma. V1 hedefi: **güvenilir cihaz‑içi tarama + kaydır‑sil deneyimi**.
