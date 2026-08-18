![image](IMG_0157)
# SpotBrief

SpotBrief is a news aggregator built for **iOS** (SwiftUI / Swift Playgrounds) and **Android** (Kotlin / Jetpack Compose). It pulls headlines from RSS feeds, sorts them into categories, generates short on‑device summaries, and can read them aloud — all without calling any external AI service.

## Features

- **RSS aggregation** — pulls from a curated list of sources per region (Russia, Kazakhstan, USA, UK, Germany) plus any custom feed you add.
- **On‑device summarization** — an offline extractive summarizer (simplified TextRank + MMR) condenses long articles; no network calls, no API keys.
- **Automatic categorization** — headlines are sorted into Politics, Sports, Economy, Technology, Science, Culture, Incidents, and Society using keyword heuristics.
- **Text‑to‑speech** — listen to a summary via the system speech synthesizer (`AVSpeechSynthesizer` on iOS, `TextToSpeech` on Android).
- **Bookmarks & read history** — save articles for later and keep track of what you've already read.
- **Search** across all fetched articles.
- **Custom sources** — add your own RSS feeds.
- **Multi‑language interface** — English, Russian, Kazakh, and German, switchable at any time in Settings.
- **Source availability checker** — shows whether each feed is currently reachable from your device.
- **Home‑screen widget** — a daily digest widget (fully functional on Android via Glance; on iOS the underlying data layer is in place but the WidgetKit extension itself isn't wired up yet, since Swift Playgrounds projects don't support a second target).
- **Morning notifications** — a daily local notification with the top story from each category, at a time you choose.

## Platforms

| | iOS | Android |
|---|---|---|
| UI framework | SwiftUI | Jetpack Compose (Material 3) |
| Minimum OS | iOS 17.0+ | Android 8.0+ (API 26) |
| Language | Swift 5.9 | Kotlin 2.0 |
| Project | `SpotBrief 20.swiftpm` | Gradle project, package `ru.matwey.spotbrief` |

The two are independent, hand‑written implementations of the same product — not a shared codebase — kept in sync feature‑for‑feature.

## Requirements

### iOS
- Xcode 15+ or Swift Playgrounds 4.5+
- iOS 17.0+
- Swift 5.9 (Swift tools version)

### Android
- Android Studio (current stable) with Android SDK installed
- Android 8.0+ (API 26) on device/emulator
- Kotlin 2.0, Gradle 8.11.1, Compose BOM 2024.10.00 (all pinned in the Gradle files — no extra setup beyond a synced SDK)

## Getting started

### iOS
1. Clone the repository:
   ```
   git clone https://github.com/<your-username>/spotbrief.git
   ```
2. Open `SpotBrief 20.swiftpm` in Xcode or Swift Playgrounds.
3. Build and run on a simulator or device running iOS 17 or later.

### Android
1. Clone the repository:
   ```
   git clone https://github.com/<your-username>/spotbrief.git
   ```
2. Open the `SpotBriefAndroid` folder in Android Studio and let it sync.
3. If Gradle can't find your SDK, create a `local.properties` file in the project root with:
   ```
   sdk.dir=/path/to/your/Android/sdk
   ```
   (Android Studio normally generates this automatically on first sync.)
4. Run on an emulator or device running Android 8.0 or later.

## Project structure

### iOS — `SpotBrief 20.swiftpm/`
```
SpotBrief 20.swiftpm/
├── Package.swift
└── Sources/
    └── SpotBrief/
        ├── SpotBriefApp.swift         # App entry point
        ├── RootTabView.swift          # Tab navigation
        ├── ContentView.swift          # Home screen
        ├── CategoryDetailView.swift
        ├── SearchView.swift
        ├── BookmarksView.swift
        ├── SettingsView.swift
        ├── OnboardingView.swift
        ├── LanguagePickerView.swift
        ├── RegionPickerView.swift
        ├── AddCustomSourceView.swift
        ├── StatsView.swift
        ├── NewsAggregatorService.swift  # Fetching & aggregation
        ├── RSSFeedParser.swift
        ├── ArticleContentFetcher.swift
        ├── SourceAvailabilityChecker.swift
        ├── NewsSummarizer.swift         # Offline summarization
        ├── NewsCategorizer.swift        # Keyword-based categorization
        ├── NewsJunkFilter.swift
        ├── SpeechReader.swift           # Text-to-speech
        ├── SettingsStore.swift
        ├── CustomSourcesStore.swift
        ├── Persistence.swift
        ├── Models.swift
        ├── Region.swift
        └── Localization.swift           # en / ru / kk / de strings
```

### Android — `SpotBriefAndroid/`
```
SpotBriefAndroid/
├── settings.gradle.kts
├── build.gradle.kts
└── app/
    └── src/main/java/ru/matwey/spotbrief/
        ├── MainActivity.kt              # App entry point
        ├── SpotBriefApplication.kt      # Shared stores & services
        ├── model/                       # NewsCategory, NewsSource, NewsItem
        ├── data/
        │   ├── NewsAggregatorService.kt # Fetching & aggregation
        │   ├── RssFeedParser.kt
        │   ├── ArticleContentFetcher.kt
        │   ├── SourceAvailabilityChecker.kt
        │   ├── NewsSummarizer.kt        # Offline summarization
        │   ├── NewsCategorizer.kt       # Keyword-based categorization
        │   ├── NewsDeduplicator.kt
        │   ├── NewsJunkFilter.kt
        │   ├── SettingsStore.kt
        │   ├── CustomSourcesStore.kt
        │   ├── Persistence.kt
        │   ├── Region.kt
        │   └── Localization.kt          # en / ru / kk / de strings
        ├── ui/
        │   ├── RootScreen.kt            # Bottom navigation
        │   └── screens/                 # Feed, Category, Search, Bookmarks,
        │                                 # Stats, Settings, Onboarding, etc.
        ├── widget/                      # Home-screen widget (Glance)
        ├── notifications/               # Morning digest notification
        └── speech/                      # Text-to-speech
```

## Privacy

All summarization and categorization happens on-device, on both platforms. The app does not send article content to any third-party AI service. It does fetch RSS feeds and article pages directly from the news sources you enable.

## License

Released under the MIT License.
