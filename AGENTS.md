# Repository Guidelines

## Project Structure & Module Organization

`Sources/MFA/` holds all app code, grouped by role: `App/` (entry point), `Models/`, `Services/` (TOTP, crypto, parsers, storage), `ViewModels/`, and `Views/` (subfolders `MenuBar/`, `Main/`, `Scanner/`, `Components/`, `Settings/`). Tests live in `Tests/MFATests/`. Assets and app config are in `Resources/` (`Assets.xcassets`, `Info.plist`, `MFA.entitlements`). The Xcode project is generated from `project.yml`; never hand-edit `MFA.xcodeproj`.

## Build, Test, and Development Commands

- `brew install xcodegen` then `xcodegen generate` — regenerate `MFA.xcodeproj` from `project.yml` after adding files.
- `./build_app.sh` — Debug build, injects plist keys (camera, `LSUIElement`), ad-hoc signs, app lands in `build/Build/Products/Debug/MFA.app`.
- `xcodebuild -scheme MFA -configuration Release build` — Release build.
- `xcodebuild test -scheme MFA -destination 'platform=macOS'` — run the test suite.

## Coding Style & Naming Conventions

Swift 6 with SwiftUI. Use 4-space indentation, camelCase for values/functions, PascalCase for types (`TOTPEngine`, `AccountStore`). One public type per file named after the type, matching existing `Services/` layout. No formatter or linter is configured; keep imports ordered and lines under ~120 columns. Follow existing `final class` and `@testable import` patterns.

## Testing Guidelines

Tests use `XCTest` (`@testable import MFA`). Name files `*Tests.swift` and methods `test<Behavior>` (e.g. `testGenerateSHA1CodeAtTime59`). Prefer RFC 6238 known-answer vectors for TOTP cases. Add a matching `*Tests.swift` for each new `Service`; run via `xcodebuild test`.

## Commit & Pull Request Guidelines

Commits follow Conventional Commits: `feat:`, `fix:`, `docs:`, with lowercase imperative summaries (e.g. `fix: add camera entitlement`). Keep one logical change per commit. PRs need a clear description, linked issues when applicable, and screenshots for UI changes. Regenerate the project before committing new source files.

## Security & Configuration Tips

Secrets are AES-256-GCM encrypted; the key resides in the macOS Keychain (`KeychainService`). Never write plaintext secrets to disk or logs. DB path: `~/Library/Application Support/MFA/mfa.db`. Update `MFA.entitlements` and `Info.plist` (camera usage) alongside any new capability.
