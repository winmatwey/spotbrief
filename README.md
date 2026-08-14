# SpotBrief

SpotBrief is an iOS news aggregator built with SwiftUI and Swift Playgrounds. It pulls headlines from RSS feeds, sorts them into categories, generates short on‑device summaries, and can read them aloud — all without calling any external AI service.

## Features

- **RSS aggregation** — pulls from a curated list of sources per region (Russia, Kazakhstan, USA, UK, Germany) plus any custom feed you add.
- **On‑device summarization** — an offline extractive summarizer (simplified TextRank + MMR) condenses long articles; no network calls, no API keys.
- **Automatic categorization** — headlines are sorted into Politics, Sports, Economy, Technology, Science, Culture, Incidents, and Society using keyword heuristics.
- **Text‑to‑speech** — listen to a summary via the system speech synthesizer.
- **Bookmarks & read history** — save articles for later and keep track of what you've already read.
- **Search** across all fetched articles.
- **Custom sources** — add your own RSS feeds.
- **Multi‑language interface** — English, Russian, Kazakh, and German, switchable at any time in Settings.
- **Source availability checker** — shows whether each feed is currently reachable from your device.

## Requirements

- Xcode 15+ or Swift Playgrounds 4.5+
- iOS 17.0+
- Swift 5.9 (Swift tools version)

## Getting started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/spotbrief.git
   ```
2. Open `SpotBrief 20.swiftpm` in Xcode or Swift Playgrounds.
3. Build and run on a simulator or device running iOS 17 or later.

## Project structure

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

## Privacy

All summarization and categorization happens on-device. The app does not send article content to any third-party AI service. It does fetch RSS feeds and article pages directly from the news sources you enable.

## License

Released under the [MIT License](LICENSE).
