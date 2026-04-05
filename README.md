# iOS Community Hub (SwiftUI)

Native SwiftUI iOS Community Hub app with live BigFuture JSON:API content, filters, and resilient pagination.

Tested on: MacBook Pro (Late 2015), macOS Monterey, Xcode 14.2.

## Quick Start (Commands Only)

Run from project root and auto-launch on simulator:

```bash
./scripts/run-ios.sh
```

Run on a specific simulator:

```bash
./scripts/run-ios.sh "iPhone SE (3rd generation)"
```

## Troubleshooting (If App Does Not Launch)

1. Ensure simulator is available:

```bash
xcrun simctl list devices available
```

2. Retry with a specific available simulator name:

```bash
./scripts/run-ios.sh "iPhone 14"
```

3. Open simulator manually, then re-run:

```bash
open -a Simulator
./scripts/run-ios.sh
```

4. If build artifacts are stale, clean and run again:

```bash
rm -rf .derivedData
./scripts/run-ios.sh
```

5. If app is installed but not foregrounded, open it from Simulator home screen (search for "CommunityHub").

## What is implemented

- Live data from BigFuture Community Hub JSON:API
- Content type switch: Video and Article
- Search filter
- Audience filter: All, Student, Parent, Educator
- Paginated loading (page size 9)
- Card UI with metadata tags
- Video thumbnails with fallback handling
- Local fallback snapshot data when network/live API fails

## Project files

The app code lives under CommunityHub:

- CommunityHub/CommunityHubApp.swift
- CommunityHub/Views
- CommunityHub/ViewModels
- CommunityHub/Services
- CommunityHub/Models

## How to run

1. Open CommunityHub.xcodeproj in Xcode.
2. Select the CommunityHub scheme.
3. Choose an iOS Simulator.
4. Build and Run.

### One command from terminal

Run with default simulator (iPhone 14):

./scripts/run-ios.sh

Run with a specific simulator name:

./scripts/run-ios.sh "iPhone SE (3rd generation)"

This repository now includes a ready-to-run Xcode project.
