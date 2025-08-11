#!/bin/bash

# Community Capital iOS Setup Script
# This script will set up the iOS project with fresh dependencies

echo "🚀 Setting up Community Capital iOS..."

# Navigate to iOS directory
cd "$(dirname "$0")/ios" || exit

# Clean any existing installations
echo "🧹 Cleaning old installations..."
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/Library/Developer/Xcode/DerivedData

# Update CocoaPods repo
echo "📦 Updating CocoaPods repositories..."
pod repo update

# Install pods
echo "📲 Installing Pod dependencies..."
pod install --repo-update

# Open the workspace
echo "✅ Setup complete! Opening Xcode..."
open CommunityCapital.xcworkspace

echo ""
echo "📝 Next steps in Xcode:"
echo "1. Clean Build Folder (Cmd + Shift + K)"
echo "2. Build and Run (Cmd + R)"
echo ""
echo "If you see any errors, try:"
echo "- Product > Clean Build Folder"
echo "- Close and reopen Xcode"
echo "- Restart Xcode if needed"
