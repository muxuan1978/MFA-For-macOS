# MFA

A native macOS TOTP authenticator app. Lives in the menu bar for quick access, with a full management window for account administration.

## Features

- **TOTP Code Generation** — RFC 6238 compliant, supports SHA-1/SHA-256/SHA-512, 6 or 8 digit codes, custom periods
- **Menu Bar Quick Access** — aligned code and countdown columns, click to copy, and a draggable bottom handle to resize the popover; height is remembered across launches
- **Global Quick Fill** — open a searchable account picker with a configurable keyboard shortcut, then copy the current code or paste it into the previously active app
- **Quick Fill Settings** — choose the shortcut, control automatic pasting, and request the macOS keyboard control permission needed to send the paste keystroke
- **Account Management** — compact cards with click-to-copy feedback, search, add, edit, delete, and drag reorder; secondary controls become more prominent on hover or keyboard focus
- **Consistent Account Styling** — shared rounded avatars with stable issuer colors; countdowns turn orange at 10 seconds and red at 5 seconds remaining
- **Search and Accessibility** — clear-search controls, helpful empty states, keyboard focus indicators, and spoken code/countdown labels
- **Always-on-top Manager** — management window stays above other apps (toggle via the pin button)
- **Encrypted Storage** — AES-256-GCM encryption for secrets, encryption key stored in macOS Keychain
- **Multiple Import Methods**
  - Camera QR scanning (Vision framework)
  - Import from image files
  - Screen region capture (drag-select a QR visible on screen; decoded directly, no save-then-open)
  - Paste `otpauth://` URIs
  - Google Authenticator migration (`otpauth-migration://offline?data=...`)
  - Manual entry
- **Export** — JSON export with QR code generation per account

## Download

Download the latest release from [GitHub Releases](https://github.com/muxuan1978/MFA-For-macOS/releases/latest).

1. Download `MFA.dmg`
2. Open the DMG and drag **MFA** to the **Applications** folder
3. Launch MFA from Applications (first launch: right-click → Open)

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
