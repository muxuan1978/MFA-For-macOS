# macOS MFA Authenticator App — Design Spec

## Overview

A native macOS app for generating TOTP verification codes, supporting multi-account management with both menu bar quick access and a full management window. Supports importing from Google Authenticator exported QR codes.

## Architecture

Single-process SwiftUI app on macOS 13+:

```
MFA App (单进程 SwiftUI)
├── App 入口
│   ├── MenuBarExtra — 菜单栏 popover，快速查看验证码
│   └── WindowGroup — 主管理窗口，账户 CRUD / 导入导出
│
├── 核心模块
│   ├── TOTPEngine — 纯 Swift TOTP 计算（RFC 6238）
│   ├── AccountStore — GRDB.swift 操作 SQLite，账户增删改查
│   └── QRScanner — Vision 框架扫描二维码
│
├── 导入/导出
│   ├── GoogleAuthImporter — 解析 Google Authenticator 迁移协议
│   ├── ManualEntryView — 手动输入密钥
│   └── ExportManager — 导出为 JSON / 批量二维码
│
└── 数据层
    └── SQLite (GRDB.swift) — accounts 表
```

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (macOS 13 Ventura+)
- **Database**: SQLite via GRDB.swift
- **QR Scanning**: Vision framework (VNDocumentCameraViewController not available on macOS; use AVCaptureSession + VNDetectBarcodesRequest)
- **TOTP**: Custom implementation per RFC 6238
- **Crypto**: CryptoKit for AES-256-GCM encryption of stored secrets
- **Dependencies (SPM)**: GRDB.swift only

## Data Model

### Account

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| issuer | String | Service name (e.g., "Google", "GitHub") |
| accountName | String | User identifier (e.g., email) |
| secret | Data (encrypted) | TOTP secret key, AES-256-GCM encrypted |
| algorithm | String | "SHA1", "SHA256", "SHA512" (default SHA1) |
| digits | Int | Code length, 6 or 8 (default 6) |
| period | Int | Step duration in seconds (default 30) |
| icon | String? | Optional icon identifier |
| sortOrder | Int | Display order |
| createdAt | Date | Creation timestamp |
| updatedAt | Date | Last modification timestamp |

### Encryption

- Secrets encrypted with AES-256-GCM before storage
- Encryption key derived from a random key stored in macOS Keychain via `Security` framework
- Random key generated on first launch

## Features

### 1. Menu Bar (MenuBarExtra)

- Click menu bar icon → popover shows list of accounts with live-updating 6-digit codes
- Each account row: icon + issuer + accountName + code + remaining seconds progress indicator
- Code auto-refreshes every 30 seconds (or per-account period)
- Click code to copy to clipboard
- "+" button to add new account
- Gear icon to open main management window

### 2. Main Window (WindowGroup)

- Sidebar: account list with search
- Main area: account detail / edit form
- Toolbar: Add, Import, Export buttons
- Drag-and-drop reordering

### 3. TOTP Code Generation

- RFC 6238 compliant
- Supports SHA1/SHA256/SHA512 algorithms
- Supports 6 and 8 digit codes
- Supports custom periods (30s default)

### 4. Google Authenticator Import

Google Authenticator export uses `otpauth-migration://offline?data=...` protocol:
- Decode base64 data from the URL
- Parse protobuf payload (AccountValue message)
- Extract: name, secret (base32), issuer, algorithm, digits, counter/type
- Support batch import from a single QR scan

### 5. Manual Account Entry

- Form fields: Issuer, Account Name, Secret Key (base32), Algorithm, Digits, Period
- Validate secret key format on input

### 6. QR Code Scanning

- Open a dedicated scanning window with camera preview
- Use AVCaptureSession for camera input + VNDetectBarcodesRequest for barcode detection
- Parse `otpauth://totp/` URIs
- Parse `otpauth-migration://` URIs for Google Authenticator imports

### 7. Account Export

- Export all accounts to JSON file
- Export individual account as QR code (otpauth:// URI encoded)
- File save dialog via NSSavePanel

## Project Structure

```
MFA/
├── MFA.xcodeproj
├── MFA/
│   ├── MFAApp.swift              — App entry with MenuBarExtra + WindowGroup
│   ├── Info.plist
│   ├── Assets.xcassets
│   ├── Models/
│   │   ├── Account.swift          — Account data model
│   │   └── TOTPAlgorithm.swift    — Enum for hash algorithms
│   ├── Services/
│   │   ├── TOTPEngine.swift       — TOTP code generation
│   │   ├── AccountStore.swift     — GRDB database operations
│   │   ├── CryptoService.swift    — AES-256-GCM encrypt/decrypt
│   │   ├── KeychainService.swift  — Keychain access for encryption key
│   │   ├── QRScanner.swift        — Camera + Vision barcode detection
│   │   ├── GoogleAuthImporter.swift — Parse otpauth-migration:// protocol
│   │   ├── OTPAuthParser.swift    — Parse otpauth:// URIs
│   │   └── ExportService.swift    — Export accounts to JSON/QR
│   ├── ViewModels/
│   │   ├── AccountsViewModel.swift
│   │   └── CodeGeneratorViewModel.swift
│   ├── Views/
│   │   ├── MenuBarView.swift      — Menu bar popover content
│   │   ├── MainWindow/
│   │   │   ├── MainWindowView.swift
│   │   │   ├── AccountListView.swift
│   │   │   ├── AccountDetailView.swift
│   │   │   └── AccountEditView.swift
│   │   ├── QRScanView.swift       — Scanning window
│   │   ├── ImportView.swift       — Import progress/results
│   │   └── Components/
│   │       ├── CodeRowView.swift
│   │       ├── CountdownView.swift
│   │       └── SearchBar.swift
│   └── Protobuf/
│       └── google_auth.proto      — Google Auth export protobuf schema
├── MFA.xcodeproj/project.pbxproj
└── Package.swift                   — SPM dependencies (GRDB.swift)
```

## Non-Goals

- iCloud sync (local-only for security)
- HOTP support (counter-based, only TOTP)
- Browser extensions
- Biometric lock (future consideration)
- Windows/Linux support
