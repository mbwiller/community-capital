# Community Capital iOS App

## 🚀 Quick Setup

### Prerequisites
- Xcode 14+ installed
- CocoaPods installed (`sudo gem install cocoapods`)
- iOS 16.0+ deployment target

### Installation Steps

1. **Install Pod Dependencies**
   ```bash
   cd /Users/matt/Desktop/community-capital/ios
   pod install --repo-update
   ```

2. **Open the Workspace (IMPORTANT!)**
   ```bash
   open CommunityCapital.xcworkspace
   ```
   ⚠️ **Always use `.xcworkspace`, never `.xcodeproj`**

3. **Clean Build Folder in Xcode**
   - Press `Cmd + Shift + K`

4. **Build and Run**
   - Press `Cmd + R` or click the Play button

## 📁 Project Structure

```
ios/
├── CommunityCapital/          # Main app code
│   ├── App/                   # App delegate and main entry
│   └── CommunityCapital/      # Features and core logic
│       ├── Core/              # Core utilities and services
│       ├── Features/          # Feature modules
│       └── Shared/            # Shared components
├── CommunityCapital.xcworkspace  # ← ALWAYS OPEN THIS
├── Podfile                    # CocoaPods dependencies
└── Pods/                      # Dependencies (auto-generated)
```

## 🔧 Troubleshooting

### If build fails with missing Pod files:
```bash
# Complete clean and reinstall
rm -rf Pods
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/Library/Developer/Xcode/DerivedData
rm Podfile.lock
pod install --repo-update
```

### For Apple Silicon Macs (M1/M2):
```bash
arch -x86_64 pod install
```

### Clear Xcode Derived Data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 📦 Dependencies

- **Stripe** - Payment processing
- **Plaid** - Bank connections
- **Firebase** - Authentication & Database
- **Lottie** - Animations
- **SnapKit** - Auto Layout
- **Alamofire** - Networking
- **Mixpanel** - Analytics

## 🎯 Important Notes

1. Always use the `.xcworkspace` file, not `.xcodeproj`
2. Run `pod install` after pulling new changes
3. Keep iOS deployment target at 16.0+
4. Ensure Firebase GoogleService-Info.plist is present

## 📱 Testing

- Simulator: iPhone 14 Pro recommended
- Physical Device: Requires Apple Developer account

---
Last Updated: August 9, 2025
