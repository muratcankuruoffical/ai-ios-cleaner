# AI Cleaner iOS - Smart Photo Organization

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

**Intelligent, on-device photo cleaning powered by AI**

[Features](#features) • [Architecture](#architecture) • [Setup](#setup) • [Privacy](#privacy)

</div>

---

## 🌟 Features

### Smart Photo Analysis (100% On-Device)
- **Duplicate Detection**: Find similar photos using Vision framework's feature extraction
- **Blur Detection**: Identify low-quality, out-of-focus images using Laplacian variance
- **Brightness Analysis**: Detect dark or overexposed photos
- **Screenshot Detection**: Automatically identify screenshots
- **Large Video Finder**: Locate space-consuming videos

### Intuitive Cleaning Experience
- **Tinder-like Swipe Interface**: Review photos with smooth, gesture-based controls
- **Smart Albums**: Organized categories for different photo types
- **Batch Operations**: Efficiently review and delete multiple photos
- **Undo Support**: Reverse accidental swipes

### Privacy First
- ✅ **100% On-Device Processing**: Photos never leave your device
- ✅ **No Cloud Upload**: Zero data transmitted to external servers
- ✅ **No Photo Access by Third Parties**: Complete privacy guarantee
- ✅ **Optional Analytics**: User-controlled, anonymous usage statistics

### Monetization
- **Free Tier**: Daily scan and swipe limits
- **Pro Subscription**: Unlimited scans, swipes, and advanced features
- **Revenue Cat Integration**: Seamless subscription management

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Minimum iOS** | iOS 16.0+ |
| **AI/ML** | Vision Framework, Core ML |
| **Image Processing** | Core Image, Accelerate/vImage |
| **Data Persistence** | Core Data |
| **Analytics** | Firebase Analytics & Crashlytics |
| **Subscriptions** | RevenueCat |

### Project Structure

```
AI Cleaner/
├── App/
│   ├── AI_CleanerApp.swift          # Main app entry point
│   └── AppRouter.swift               # Navigation coordinator
├── Core/
│   ├── Services/
│   │   ├── PhotoLibraryService.swift    # Photo access & management
│   │   ├── VisionService.swift          # Feature extraction
│   │   ├── SimilarityService.swift      # Duplicate detection
│   │   ├── BlurDetector.swift           # Quality analysis
│   │   ├── DarknessDetector.swift       # Brightness analysis
│   │   ├── ScreenshotDetector.swift     # Screenshot detection
│   │   └── VideoAnalyzer.swift          # Video analysis
│   ├── Persistence/
│   │   ├── CoreDataStack.swift          # Core Data setup
│   │   └── AICleanerModel.xcdatamodeld  # Data models
│   ├── Monetization/
│   │   └── RevenueCatManager.swift      # Subscription management
│   └── Analytics/
│       └── AnalyticsManager.swift       # Event tracking
├── Features/
│   ├── Onboarding/
│   │   └── OnboardingView.swift         # Welcome & permissions
│   ├── Scanner/
│   │   ├── ScanCoordinator.swift        # Scan orchestration
│   │   └── ScanProgressView.swift       # Progress UI
│   ├── Duplicates/
│   │   └── SwipeDeckView.swift          # Tinder-like swipe UI
│   ├── SmartAlbums/
│   │   └── SmartAlbumsView.swift        # Categorized collections
│   ├── Reports/
│   │   └── DashboardView.swift          # Main dashboard
│   ├── Paywall/
│   │   └── PaywallView.swift            # Subscription screen
│   └── Settings/
│       └── SettingsView.swift           # App settings
└── Resources/
    └── Info.plist                       # App configuration
```

---

## 🚀 Setup

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS 16.0+ device or simulator
- Apple Developer Account (for device testing)

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/ai-ios-cleaner.git
   cd ai-ios-cleaner
   ```

2. **Open in Xcode**
   ```bash
   open "AI Cleaner.xcodeproj"
   ```

   Or create a new Xcode project and add the source files.

3. **Add SPM Dependencies**

   In Xcode, go to: `File > Add Package Dependencies...`

   Add the following packages:

   - **RevenueCat**: `https://github.com/RevenueCat/purchases-ios.git` (4.31.0+)
   - **Firebase**: `https://github.com/firebase/firebase-ios-sdk.git` (10.19.0+)
     - Select: FirebaseAnalytics, FirebaseCrashlytics

4. **Configure RevenueCat**

   - Create account at [RevenueCat](https://www.revenuecat.com/)
   - Create app: `ai-cleaner-ios`
   - Set up products and entitlements
   - Copy API key to `RevenueCatManager.swift:38`

   ```swift
   private let apiKey = "YOUR_REVENUECAT_API_KEY"
   ```

5. **Configure Firebase**

   - Create project at [Firebase Console](https://console.firebase.google.com/)
   - Add iOS app with bundle ID
   - Download `GoogleService-Info.plist`
   - Add to Xcode project
   - Uncomment Firebase initialization in:
     - `AnalyticsManager.swift`
     - `AI_CleanerApp.swift`

6. **Set Bundle Identifier**

   - Open project settings in Xcode
   - Set your unique bundle identifier
   - Configure signing & capabilities

7. **Build and Run**
   ```
   ⌘ + R
   ```

---

## 📱 Usage Flow

1. **Onboarding**: Privacy explanation → Photo permission request
2. **Dashboard**: Start scan → View progress
3. **Results**: Review potential savings → Navigate to Smart Albums
4. **Smart Albums**: Select category (Duplicates, Blurry, etc.)
5. **Swipe Review**: Swipe right to delete, left to keep
6. **Cleanup**: Confirm deletion → Photos moved to Recently Deleted

---

## 🔒 Privacy & Security

### Data Processing
- All image analysis happens **100% on-device**
- Feature vectors stored locally in Core Data
- No photos uploaded to external servers

### Permissions
- **Photo Library**: Required for scanning and organizing
- **Analytics** (Optional): Anonymous usage statistics

### Data Storage
- **Core Data**: Feature vector cache, scan history
- **UserDefaults**: App preferences, onboarding state
- **No Cloud Sync**: All data stays on device

---

## 🧪 Testing

### Test Scenarios

| Scenario | Library Size | Expected Result |
|----------|--------------|-----------------|
| Small    | 100-500      | < 10s scan time |
| Medium   | 500-5,000    | < 60s scan time |
| Large    | 5,000-50,000 | < 5min scan time |

### Manual Testing Checklist

- [ ] Onboarding flow completes successfully
- [ ] Photo permission granted/denied states
- [ ] Scan progresses and completes
- [ ] Similar photos grouped correctly
- [ ] Blur detection accuracy > 80%
- [ ] Screenshot detection works
- [ ] Swipe gestures responsive
- [ ] Deletion confirmation works
- [ ] Paywall displays correctly
- [ ] Settings persist

---

## 🎯 Roadmap

### V1.0 (Current)
- ✅ On-device photo analysis
- ✅ Tinder-like swipe interface
- ✅ Smart Albums
- ✅ RevenueCat integration
- ✅ Firebase Analytics

### V1.1 (Planned)
- [ ] Video similarity detection (audio fingerprinting)
- [ ] Photo optimization (4K → 1080p)
- [ ] Widget support
- [ ] App Shortcuts
- [ ] Multi-language support (TR, EN, RU)

### V1.2 (Future)
- [ ] Hidden album automation
- [ ] Advanced ANN for faster similarity
- [ ] Live Photo cleanup
- [ ] Duplicate video detection

---

## 📊 Performance Considerations

### Optimization Strategies
- **Batch Processing**: Process assets in chunks of 50
- **Background Queues**: Heavy computation off main thread
- **Caching**: Store feature vectors to avoid recomputation
- **Incremental Scanning**: Only analyze new/modified photos
- **Thumbnail Loading**: Use PHCachingImageManager

### Memory Management
- Use `autoreleasepool` for large batch operations
- Release image data after feature extraction
- Implement memory warnings handling

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Add documentation for public APIs
- Write unit tests for business logic

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- **Email**: support@aicleaner.app
- **Issues**: [GitHub Issues](https://github.com/yourusername/ai-ios-cleaner/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/ai-ios-cleaner/wiki)

---

## 🙏 Acknowledgments

- Apple Vision Framework for feature extraction
- RevenueCat for subscription infrastructure
- Firebase for analytics and crash reporting
- SwiftUI community for UI inspiration

---

<div align="center">

**Made with ❤️ using Swift and SwiftUI**

⭐ Star this repo if you find it helpful!

</div>
