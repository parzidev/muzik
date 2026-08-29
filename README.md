# Şarkı Sözü iOS App

A native iOS lyrics application developed in Swift and preserved with its Xcode project history and assets.

The app provides a mobile interface for discovering and viewing song lyrics. The repository includes application source, Xcode configuration, resources, and historical build/archive material from development.

## What this project includes

- Native iPhone/iPad interface
- Song and lyrics browsing flows
- Bundled visual resources
- Xcode project for simulator/device development
- Historical archive retained for reference

## Technology

- Swift
- iOS SDK
- Xcode
- Apple application resources

## Repository structure

- `SarkiSozu/` — Application source and resources.
- `*.xcodeproj` — Xcode project.
- `*.xcarchive` — Historical build archives.
- `CertificateSigningRequest.certSigningRequest` — Historical signing request.

## Getting started

Use macOS and Xcode. Open the project, select an available scheme and simulator, configure signing if required, and run with **Product → Run**.
Detected Xcode project: `SarkiSozu/SarkiSozu.xcodeproj`, `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu.xcodeproj`.

## Configuration and data

- Open the Xcode project in `SarkiSozu/` or the repository root and select a valid scheme.
- Configure your own bundle identifier and Apple development team before device use.
- Review any external lyric-service endpoint before relying on it.

## Development and validation

- Keep changes focused on the relevant module or subproject and verify the user-facing path manually before publishing.
- Do not commit generated build output, local environments, caches, logs, or credentials unless an artifact is intentionally retained as source material.

## Security and responsible use

- Signing requests, certificates, provisioning profiles, and archives should not be stored in Git. Use ignored local signing configuration.
- Verify that lyrics and artwork may be used or redistributed in the target product.

## Project status

A legacy iOS application archive. Current Xcode and iOS SDK versions may require migration changes before a clean build.

## License

No repository-wide license file is currently provided. Unless the owner grants permission, all rights are reserved.
