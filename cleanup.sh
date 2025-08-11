#!/bin/bash

# Community Capital Cleanup Script
# Run this script to clean temporary files and caches

echo "🧹 Starting Community Capital cleanup..."

# Remove .DS_Store files
echo "Removing .DS_Store files..."
find . -name '.DS_Store' -type f -delete

# Clean iOS build artifacts
echo "Cleaning iOS build artifacts..."
if [ -d "ios" ]; then
    find ios -name 'xcuserdata' -type d -exec rm -rf {} + 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
fi

# Option to clean Pods (commented out by default)
# echo "Cleaning Pods (requires reinstall)..."
# rm -rf ios/Pods
# rm -f ios/Podfile.lock

# Option to clean node_modules (commented out by default)
# echo "Cleaning node_modules (requires reinstall)..."
# rm -rf backend/node_modules
# rm -f backend/package-lock.json

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. If you cleaned Pods: cd ios && pod install"
echo "2. If you cleaned node_modules: cd backend && npm install"
echo "3. Open ios/CommunityCapital.xcworkspace in Xcode"
