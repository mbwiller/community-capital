Write-Host "🚀 Setting up Community Capital project structure..." -ForegroundColor Green

# Create .gitignore
$gitignoreContent = @"
# Dependencies
node_modules/
*.lock
package-lock.json

# Environment
.env
.env.local
.env.*.local
*.env

# iOS
*.xcuserstate
*.xcworkspace/xcuserdata/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM
Pods/
.build/
xcuserdata/

# macOS
.DS_Store
*.swp
*~.nib

# Secrets
*.pem
*.key
*.p12
*.p8
*.mobileprovision

# IDE
.idea/
.vscode/
*.sublime-*

# Testing
coverage/
*.lcov
.nyc_output

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*

# Build
dist/
build/
out/
.next/
"@
Set-Content -Path ".gitignore" -Value $gitignoreContent
Write-Host "✅ Created .gitignore" -ForegroundColor Yellow

# Create README.md
$readmeContent = @"
# 💸 Community Capital

> Split bills instantly. Invest together. Build wealth with friends.

## 🚀 Vision

Community Capital transforms how groups handle money together - from splitting tonight's dinner to building tomorrow's wealth.

## ✨ Core Features

### Phase 1: Payment Splitting (MVP)
- 📸 **Smart Receipt Scanning** - AI-powered OCR instantly itemizes bills
- 👥 **Real-time Splitting** - Each person claims their items
- 💳 **Virtual Card Magic** - One card payment, multiple simultaneous charges
- 🔐 **Face ID Security** - Biometric confirmation for all transactions

### Phase 2: Collective Investing (Coming Soon)
- 📈 **Group Portfolios** - Pool money for fractional investing
- 🗳️ **Democratic Decisions** - Vote on investment choices
- 🤖 **AI Advisor** - Get personalized group investment insights
- 📊 **Social Finance** - Learn and grow wealth together

## 🏗️ Architecture

\`\`\`
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   iOS App   │────▶│   Backend    │────▶│   Railway   │
│  (SwiftUI)  │     │  (Node.js)   │     │   (Cloud)   │
└─────────────┘     └──────────────┘     └─────────────┘
       │                    │                     │
       ▼                    ▼                     ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│    Plaid    │     │    Stripe    │     │  Database   │
│   (Banks)   │     │  (Payments)  │     │ (PostgreSQL)│
└─────────────┘     └──────────────┘     └─────────────┘
\`\`\`

## 🚦 Quick Start

### Prerequisites
- Xcode 15+ (for iOS development)
- Node.js 18+ (for backend)
- PostgreSQL 14+ (for database)

### Backend Setup
\`\`\`bash
cd backend
npm install
copy .env.example .env
# Add your API keys to .env
npm run dev
\`\`\`

### iOS Setup
\`\`\`bash
cd ios
pod install
open CommunityCapital.xcworkspace
# Update Config.swift with your backend URL
# Run on simulator or device
\`\`\`

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Built with ❤️ by the Community Capital team
"@
Set-Content -Path "README.md" -Value $readmeContent
Write-Host "✅ Created README.md" -ForegroundColor Yellow

# Create backend package.json
$packageJsonContent = @"
{
  "name": "community-capital-backend",
  "version": "1.0.0",
  "description": "Backend for Community Capital payment splitting and investing platform",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "lint": "eslint src/",
    "migrate": "knex migrate:latest",
    "seed": "knex seed:run"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "dotenv": "^16.3.1",
    "stripe": "^13.5.0",
    "plaid": "^21.0.0",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "express-rate-limit": "^6.10.0",
    "express-validator": "^7.0.1",
    "winston": "^3.10.0",
    "morgan": "^1.10.0",
    "socket.io": "^4.5.4",
    "redis": "^4.6.7",
    "bull": "^4.11.3",
    "knex": "^2.5.1",
    "pg": "^8.11.3",
    "twilio": "^4.18.0",
    "aws-sdk": "^2.1450.0",
    "uuid": "^9.0.0",
    "axios": "^1.5.0",
    "multer": "^1.4.5-lts.1",
    "sharp": "^0.32.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.6.4",
    "supertest": "^6.3.3",
    "eslint": "^8.48.0",
    "eslint-config-airbnb-base": "^15.0.0",
    "eslint-plugin-import": "^2.28.1",
    "@types/node": "^20.5.7"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
"@
Set-Content -Path "backend\package.json" -Value $packageJsonContent
Write-Host "✅ Created backend/package.json" -ForegroundColor Yellow

# Create .env.example
$envExampleContent = @"
# Node Environment
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000

# Database (Railway PostgreSQL)
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Redis (Railway Redis)
REDIS_URL=redis://default:password@host:6379

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=7d

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Plaid
PLAID_CLIENT_ID=xxx
PLAID_SECRET=xxx
PLAID_ENV=sandbox
PLAID_PRODUCTS=auth,transactions
PLAID_COUNTRY_CODES=US

# Twilio (SMS)
TWILIO_ACCOUNT_SID=xxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_PHONE_NUMBER=+1234567890

# AWS S3 (Receipt Storage)
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_REGION=us-west-2
AWS_S3_BUCKET=community-capital-receipts

# Sentry (Error Tracking)
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx

# Analytics
MIXPANEL_TOKEN=xxx
SEGMENT_WRITE_KEY=xxx
"@
Set-Content -Path "backend\.env.example" -Value $envExampleContent
Write-Host "✅ Created backend/.env.example" -ForegroundColor Yellow

# Create railway.json
$railwayContent = @"
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "cd backend && npm ci"
  },
  "deploy": {
    "startCommand": "cd backend && npm start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10,
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30
  }
}
"@
Set-Content -Path "railway.json" -Value $railwayContent
Write-Host "✅ Created railway.json" -ForegroundColor Yellow

# Create iOS Podfile
$podfileContent = @"
platform :ios, '16.0'
use_frameworks!

target 'CommunityCapital' do
  # Payments
  pod 'Stripe'
  pod 'Plaid'
  
  # Firebase
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Analytics'
  
  # UI/UX
  pod 'Lottie'
  pod 'SnapKit'
  
  # Networking
  pod 'Alamofire'
  
  # Analytics
  pod 'Mixpanel-swift'
  
  target 'CommunityCapitalTests' do
    inherit! :search_paths
    pod 'Quick'
    pod 'Nimble'
  end
end
"@
Set-Content -Path "ios\Podfile" -Value $podfileContent
Write-Host "✅ Created ios/Podfile" -ForegroundColor Yellow

# Create GitHub Action for iOS
$iosActionContent = @"
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_15.0.app
      
    - name: Install CocoaPods
      run: |
        cd ios
        pod install
        
    - name: Build
      run: |
        cd ios
        xcodebuild build -workspace CommunityCapital.xcworkspace \
          -scheme CommunityCapital \
          -destination 'platform=iOS Simulator,name=iPhone 15'
"@
Set-Content -Path ".github\workflows\ios.yml" -Value $iosActionContent
Write-Host "✅ Created GitHub Actions workflow" -ForegroundColor Yellow

Write-Host "`n✨ Setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Copy the iOS code from the artifacts into ios/CommunityCapital/" -ForegroundColor White
Write-Host "2. Copy the backend server code into backend/src/server.js" -ForegroundColor White
Write-Host "3. Run: cd backend && npm install" -ForegroundColor White
Write-Host "4. Configure your .env file with API keys" -ForegroundColor White
Write-Host "5. Commit to GitHub: git add . && git commit -m 'Initial commit'" -ForegroundColor White
Write-Host "6. Push to GitHub: git remote add origin https://github.com/mbwiller/community-capital.git" -ForegroundColor White
Write-Host "7. Push: git push -u origin main" -ForegroundColor White