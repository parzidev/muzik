# Muzik

> Engineering README reviewed from the repository state on 2026-09-05. Observed facts are separated from items that still need manual verification.

**Repository:** [parzidev/muzik](https://github.com/parzidev/muzik)  
**Visibility:** public  
**Default branch:** `main`  
**Latest GitHub push observed:** `2026-08-29T09:12:27Z`  
**Scanned HEAD:** `3f6dc1d6146b95a5e4565202e0743893a7bbcc85`  
**Repository description:** Not set on GitHub.

## Purpose and scope

A native iOS lyrics application developed in Swift and preserved with its Xcode project history and assets.

The repository currently contains **159** source-tree files, including **44** code-like files. This README describes the repository as it exists in the scanned snapshot; it is not a claim that every historical or runtime path is still active.

## Capability inventory

### README evidence

The source README exposes these sections: `Şarkı Sözü iOS App`, `What this project includes`, `Technology`, `Repository structure`, `Getting started`, `Configuration and data`, `Development and validation`, `Security and responsible use`, `Project status`, `License`.

### Detected technology profile

| `Swift` | 44 code-like files |

### Project structure

Top-level paths observed:

- `.DS_Store`
- `.claude`
- `CertificateSigningRequest.certSigningRequest`
- `README.md`
- `SarkiSozu.xcarchive`
- `SarkiSozu`
- `parzi.xcarchive`

Key entrypoint candidates:

- `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu/SarkiSozuApp.swift`
- `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Info.plist`
- `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Resources/DWARF/SarkiSozu`
- `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Resources/Relocations/aarch64/SarkiSozu.yml`
- `SarkiSozu/SarkiSozu/SarkiSozuApp.swift`
- `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Info.plist`
- `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Resources/DWARF/parzi`
- `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Resources/Relocations/aarch64/parzi.yml`

## Architecture and runtime shape

| Area | Observed evidence |
| --- | --- |
| Entrypoint candidates | `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu/SarkiSozuApp.swift`, `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Info.plist`, `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Resources/DWARF/SarkiSozu`, `SarkiSozu.xcarchive/dSYMs/SarkiSozu.app.dSYM/Contents/Resources/Relocations/aarch64/SarkiSozu.yml`, `SarkiSozu/SarkiSozu/SarkiSozuApp.swift`, `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Info.plist`, `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Resources/DWARF/parzi`, `parzi.xcarchive/dSYMs/parzi.app.dSYM/Contents/Resources/Relocations/aarch64/parzi.yml` |

Interpretation boundary: filenames and manifests show where a component may start, but they do not prove deployment topology, request flow, persistence semantics, or production readiness. Those items should be confirmed against the implementation before making operational claims about the project.

## Code-level signals

The following patterns were extracted from readable code files. They are navigation aids for the next human review, not a substitute for reading the implementation:

**Named functions/classes/types observed:** `ContentView`, `Tab`, `DesignSystem`, `Color`, `Typography`, `Spacing`, `CornerRadius`, `Shadow`, `DesignSystem_Previews`, `Playlist`, `Song`, `LyricsData`, `RenderBlock`, `BlockType`, `CodingKeys`, `SarkiSozuApp`, `MetricsService`, `SongDataService`, `LoadError`, `Theme`, `MusicTheory`, `ChordInfo`, `MockSongRepository`, `HomeViewModel`, `SearchViewModel`, `SongDetailViewModel`, `DisplayMode`, `SettingsViewModel`, `ChordLibraryView`, `ChordData`, `ChordDatabase`, `ChordDiagramView`, `ChordSize`, `ChordFretboardView`, `SongCardView`, `FilterChip`, `EmptyStateView`, `SkeletonView`, `SectionHeader`, `Components_Previews`, `SongRowView`, `FavoritesView`, `HomeView`, `PlaylistDetailView`, `AddSongsToPlaylistView`, `PlaylistsView`, `SearchView`, `SearchFilterSheet`, `SettingsView`, `DiagnosticsView`, `AboutView`, `FeedbackView`, `SongDetailView`, `ChordPart`, `ChipView`, `ControlStepper`, `SelectPlaylistSheet`, `SongsView`, `MusicTheoryTests`

**Top-level import/module signals:** `SwiftUI`, `Foundation`, `MetricKit`, `Combine`, `XCTest`

## Setup and operation

The most relevant source README material is reproduced below:

## Getting started

Use macOS and Xcode. Open the project, select an available scheme and simulator, configure signing if required, and run with **Product → Run**.
Detected Xcode project: `SarkiSozu/SarkiSozu.xcodeproj`, `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu.xcodeproj`.

## Configuration and data

- Open the Xcode project in `SarkiSozu/` or the repository root and select a valid scheme.
- Configure your own bundle identifier and Apple development team before device use.
- Review any external lyric-service endpoint before relying on it.

Static setup/deployment evidence:

- Docker files: none detected
- Build/config manifests: none detected
- Configuration-like paths: `.claude/settings.local.json`, `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu/Views/SettingsView.swift`, `SarkiSozu/SarkiSozu/Views/SettingsView.swift`

### Command evidence

_No fenced command/config blocks were detected in the source README._

## API, integrations, and data flow

No API/integration section was detected in the source README. External boundaries require code-level review before publication.

Before publishing a public README, confirm the following from code and deployment configuration:

- inbound routes, ports, webhooks, and authentication middleware;
- outbound providers, rate limits, retries, and failure behavior;
- persistence files/databases and backup/restore expectations;
- whether any endpoint can mutate external state.

## Configuration and secrets

Detected names (names only; values were intentionally excluded):

No conventional environment-variable names were detected in the sampled manifests/entrypoints.

Configuration paths observed:

- `.claude/settings.local.json`
- `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozu/Views/SettingsView.swift`
- `SarkiSozu/SarkiSozu/Views/SettingsView.swift`

Do not paste real tokens, passwords, private keys, cookies, or production URLs into this README or a public README. Replace them with placeholders and document where the operator should provision them.

## Security and privacy

## Security and responsible use

- Signing requests, certificates, provisioning profiles, and archives should not be stored in Git. Use ignored local signing configuration.
- Verify that lyrics and artwork may be used or redistributed in the target product.

Minimum publication checklist:

- document trust boundaries and the intended network exposure;
- explain authentication and authorization separately;
- state whether logs, uploads, identifiers, or third-party data are retained;
- include a responsible-use note where the project interacts with Steam, Kick, Riot, Spotify, Cloudflare, or other external platforms;
- keep example configuration values synthetic.

## Validation and maintenance

## Development and validation

- Keep changes focused on the relevant module or subproject and verify the user-facing path manually before publishing.
- Do not commit generated build output, local environments, caches, logs, or credentials unless an artifact is intentionally retained as source material.

Test-like paths were detected, but no tests were executed during this documentation-only scan.

Test-like paths observed:

- `.claude/worktrees/silly-rubin-48196d/SarkiSozu/SarkiSozuTests/MusicTheoryTests.swift`
- `SarkiSozu/SarkiSozuTests/MusicTheoryTests.swift`

CI/workflow and maintenance evidence should be verified before adding badges or claiming release guarantees.

## Known gaps and verification notes

- Repository snapshot was available for static inspection.
- This was a static documentation scan; no repository code, containers, network services, or test suites were executed.
- “Detected” means a filename, README section, manifest, or sampled entrypoint matched the scanner; it is not a security audit.
- README sections may describe an older state than the current code. Compare the published README with the latest default-branch files before committing it upstream.

## Reference README material (sanitized)

The relevant source README is retained below as reference material, with credential-shaped values removed.

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
