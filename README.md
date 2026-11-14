# PremedLog

An iPhone app for pre-med students. You log clinical, shadowing, volunteering and research hours in about 10 seconds and jot down a short reflection each time. When application season comes, the app turns those notes into the 15 AMCAS Work & Activities entries: 700 characters each, plus 1,325 for up to 3 "most meaningful" experiences.

SwiftUI + SwiftData + StoreKit 2 + WidgetKit. iOS 17+, iPhone only, Swift 5 language mode.

## Open and run

```sh
open PremedLog.xcodeproj        # then pick an iPhone simulator and press Run
```

The project is generated from `project.yml`. After adding or removing files, regenerate it:

```sh
xcodegen generate
```

### Command-line builds

On this machine `xcode-select` points at the Command Line Tools, so prefix every `xcodebuild` and `xcrun` command with `DEVELOPER_DIR`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project PremedLog.xcodeproj -scheme PremedLog \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath build build
```

### Launch arguments (for screenshots and debugging)

| Argument | Effect |
|---|---|
| `-sampleData` | Replaces all data with realistic sample data and skips onboarding |
| `-tab dashboard\|activities\|application\|settings` | Opens on that tab |
| `-openFirst` | Pushes the first activity detail (Activities tab) or AMCAS entry (AMCAS tab) |
| `-quickLog` | Opens the log sheet |
| `-paywall` | Opens the paywall |
| `-pro` | DEBUG builds only: unlocks Pro without a purchase |

Example: `xcrun simctl launch booted com.premedlog.app -sampleData -pro -tab application`

## Testing purchases

`PremedLog.storekit` is a local StoreKit configuration file, already set in the scheme (Run › Options › StoreKit Configuration). It defines:

| Product ID | Type | Price |
|---|---|---|
| `premedlog.pro.monthly` | Auto-renewable (group "PremedLog Pro") | $4.99 / month |
| `premedlog.pro.yearly` | Auto-renewable (same group), 1-week free trial | $29.99 / year |
| `premedlog.pro.lifetime` | Non-consumable | $49.99 |

To test a purchase, run from Xcode (⌘R), open Settings › Upgrade to Pro, and buy. No Apple ID is needed. To reset, open Debug › StoreKit › Manage Transactions in Xcode and delete the transactions.

The StoreKit config only applies when Xcode launches the app. If you launch with `simctl` or from the home screen, the paywall shows fallback prices and the purchase button stays disabled.

**Free tier:** unlimited logging, the dashboard, the small home-screen widget and up to 5 activities.
**Pro:** unlimited activities, "Draft from my notes", PDF/CSV export, the medium widget and the Lock Screen widgets.

## Architecture

```
PremedLog/
  App/            PremedLogApp (ModelContainer, environment), RootView (tabs, sheets, widget sync)
  Models/         Activity, LogEntry (SwiftData), ExperienceType (the 19 AMCAS types)
  Services/       EntitlementManager (StoreKit 2), DraftService (Remote + Local),
                  ExportService (PDF + CSV), ReminderService, ShiftTimer,
                  SnapshotService (widget JSON), SampleData, Stats/Goals, AppState
  Views/          Dashboard, QuickLog, Activities, Application (AMCAS Builder),
                  Paywall, Settings (+ Export), Onboarding, Components
Shared/           CategoryGroup, WidgetSnapshot, SharedStore (used by both targets)
Widget/           WidgetKit extension: small/medium home + circular/rectangular/inline lock screen
```

- **Widget data:** whenever activities, entries, goals or Pro status change, the app writes `widget-snapshot.json` into the App Group container (`group.com.premedlog.shared`) and calls `WidgetCenter.shared.reloadAllTimelines()`. The widget only reads that file and never opens the SwiftData store.
- **Shift timer:** the start time and activity ID are stored in `UserDefaults`, so a running shift survives the app being relaunched.
- **AI drafts:** `DraftServiceFactory` returns `RemoteDraftService` when `AppConfig.draftProxyURL` is set. Otherwise it returns `LocalDraftService`, which builds a draft on the device from a template using the activity's role, hours, dates and starred reflections, trimmed to the character limit.

## What's needed to ship

1. **A paid Apple Developer account ($99/yr).** Set `DEVELOPMENT_TEAM`, switch to automatic signing, and register the App Group `group.com.premedlog.shared` for both bundle IDs (`com.premedlog.app` and `com.premedlog.app.widget`).
2. **App Store Connect products** with exactly the IDs above: the two subscriptions in one subscription group, and the lifetime purchase as a non-consumable. Add the yearly free-trial offer if you want it.
3. **An AI proxy server** if you want real AI drafts. It should accept the `DraftRequest` JSON via POST and return `{ "draft": "..." }`, keep the LLM API key on the server only (never in the app), check the user's Pro entitlement (e.g. App Store Server API / signed transaction), and rate-limit requests. Put its URL in `AppConfig.draftProxyURL`.
4. **App Store metadata:** a privacy policy and terms URLs (subscriptions require them), screenshots (use `-sampleData`), and a privacy nutrition label. Data stays on the device, and only the reflections are sent if the proxy is enabled.
5. **Optional:** iCloud sync. That needs the CloudKit entitlement, and every SwiftData relationship must be optional to be CloudKit-compatible.

PremedLog is not affiliated with the AAMC. AMCAS is a registered trademark of the AAMC.
