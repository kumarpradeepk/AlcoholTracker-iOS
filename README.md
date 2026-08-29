# Alcohol Tracker — iOS

Native SwiftUI app, iOS 17+. Bundle id `com.mtss.alcoholtracker`.

## Stack

- **SwiftUI + SwiftData**, iOS 17.0+
- **RevenueCat** (`purchases-ios-spm`) for the Pro entitlement — `Data/EntitlementStore.swift`
- **HealthKit** (write-only, `numberOfAlcoholicBeverages`), opt-in from Settings
- **LocalAuthentication** for App Lock, **UserNotifications** for daily reminders

## Layout

```
AlcoholTracker/
  App/         entry point, AppModel, RootView
  Data/        SwiftData models, settings store, EntitlementStore
  Domain/      AlcoholMath, StatsEngine, presets, units config
  Screens/     Onboarding, Paywall, Diary, LogSheet, Statistics, Settings…
  Components/  cards, chips, rings, charts, glasses, tab bar + FAB, overlays
  Theme/       design tokens (light + dark), motion curves, shared styles
  Util/        haptics, CSV export, backup, reminders, Health sync, app lock
```

## Build

Open `AlcoholTracker.xcodeproj` in Xcode 16+, select a simulator, run. The
project uses a synchronized root group — new files under `AlcoholTracker/`
join the target automatically. Swift Package dependencies resolve on first open.

## Note

This repo holds application code only. `Localizable.xcstrings` is a generated
artifact — the translation sources and generator live in the workspace outside
this repo and are not committed here.
