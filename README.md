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

\\\
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
\\\

## 🚦 Quick Start

### Prerequisites
- Xcode 15+ (for iOS development)
- Node.js 18+ (for backend)
- PostgreSQL 14+ (for database)

### Backend Setup
\\\ash
cd backend
npm install
copy .env.example .env
# Add your API keys to .env
npm run dev
\\\

### iOS Setup
\\\ash
cd ios
pod install
open CommunityCapital.xcworkspace
# Update Config.swift with your backend URL
# Run on simulator or device
\\\

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Built with ❤️ by the Community Capital team
