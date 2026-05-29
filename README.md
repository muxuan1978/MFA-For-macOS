# MFA

A native macOS TOTP authenticator app. Lives in the menu bar for quick access, with a full management window for account administration.

## Features

- **TOTP Code Generation** — RFC 6238 compliant, supports SHA-1/SHA-256/SHA-512, 6 or 8 digit codes, custom periods
- **Menu Bar Quick Access** — popover with live-updating codes, click to copy, countdown timer
- **Account Management** — card grid layout with search, add, edit, delete, and drag reorder
- **Encrypted Storage** — AES-256-GCM encryption for secrets, encryption key stored in macOS Keychain
- **Multiple Import Methods**
  - Camera QR scanning (Vision framework)
  - Import from image files
  - Paste `otpauth://` URIs
  - Google Authenticator migration (`otpauth-migration://offline?data=...`)
  - Manual entry
- **Export** — JSON export with QR code generation per account

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```bash
# Install XcodeGen (if not already)
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build
xcodebuild -scheme MFA -configuration Release build
```

The built app is in `build/Build/Products/Release/MFA.app`.

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 6.0 |
| UI | SwiftUI |
| Database | SQLite via GRDB.swift 7.0 |
| Crypto | CryptoKit (AES-256-GCM) |
| QR Scanning | Vision + AVFoundation |
| Build | XcodeGen + SPM |

## Architecture

```
Sources/MFA/
├── App/            # App entry point
├── Models/         # Account, TOTPAlgorithm
├── Services/       # TOTPEngine, AccountStore, CryptoService,
│                   # GoogleAuthParser, OTPAuthParser, ExportService...
├── ViewModels/     # AccountsViewModel, CodeViewModel
└── Views/
    ├── MenuBar/    # Menu bar popover
    ├── Main/       # Management window (card grid)
    ├── Scanner/    # QR camera view
    └── Components/ # Reusable UI components
```

## Database

Accounts are stored in SQLite at `~/Library/Application Support/MFA/mfa.db`. Secrets are encrypted with AES-256-GCM; the encryption key lives in the macOS Keychain. No plaintext secrets are ever written to disk.

## License

Private project.
