# Community Capital Platform

A comprehensive financial platform with iOS app and backend API for community-driven capital management.

## Project Structure

```
community-capital/
├── ios/                    # Native iOS Application
│   ├── CommunityCapital/   # Swift/SwiftUI source code
│   └── Podfile            # iOS dependencies
├── backend/               # Node.js Backend API
│   ├── src/              # API source code
│   └── package.json      # Node dependencies
└── .github/              # GitHub workflows
```

## Quick Start

### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your credentials
npm run dev
```

### iOS Setup
```bash
cd ios
pod install --repo-update
open CommunityCapital.xcworkspace
```
Then build and run in Xcode (Cmd + R)

## Tech Stack

### iOS
- Swift/SwiftUI
- Firebase (Auth & Firestore)
- Stripe & Plaid SDKs
- CocoaPods for dependency management

### Backend
- Node.js & Express
- PostgreSQL with Knex.js
- Redis for caching
- Socket.io for real-time features
- JWT authentication

## Development Notes

### Key Commands

**Backend:**
- `npm run dev` - Start development server
- `npm test` - Run tests
- `npm run lint` - Check code style

**iOS:**
- Always open `.xcworkspace`, not `.xcodeproj`
- Clean build: Cmd + Shift + K
- Run: Cmd + R

### Environment Variables
Backend requires `.env` file with:
- Database credentials
- API keys for Stripe, Plaid, Twilio
- JWT secrets
- Redis configuration

## Troubleshooting

### iOS Build Issues
If you encounter missing Pod files:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Backend Issues
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

## Documentation

- [iOS Setup Guide](./ios/README.md)
- [Backend API Docs](./backend/README.md)

## Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request

## License

Proprietary - All rights reserved

---
Last Updated: August 9, 2025
