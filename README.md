# WeatherForecast

## 1. Project overview

WeatherForecast is an iOS app that helps users decide what activities are suitable in a city over the next 7 days.

Users search for a city and see daily rankings for:
- Skiing
- Surfing
- Outdoor sightseeing
- Indoor sightseeing

Each activity receives a score from **0–100**, a short explanation, and a confidence level. If there is not enough essential data to score an activity—for example, wave data for surfing—it is shown as **Unavailable** rather than receiving a misleading score.

## 2. Technologies

- **Platform:** iOS 18.2+, iPhone
- **Language:** Swift (Swift 5 mode; also builds in Swift 6 mode with strict concurrency)
- **UI:** SwiftUI with `@Observable` view models
- **Concurrency:** async/await and actors
- **Testing:** XCTest and XCUITest
- **Dependencies:** No third-party packages; Apple frameworks only
- **Weather data:** Open-Meteo Geocoding, Forecast, and Marine APIs; no API key required

## 3. Architecture

The app uses **MVVM + Clean Architecture**, organized by feature:

```text
WeatherForecast/
├── App/                  App entry and AppContainer
├── Utility/              NetworkManager, Endpoint, cache, view state
└── Features/
    ├── CitySearch/       Search city: Domain, DataLayer, Presentation
    └── ActivityRanking/ Rank activities: Domain, DataLayer, Presentation
```

### What each layer does

- **Presentation:** SwiftUI screens and view models. View models manage `idle`, `loading`, `loaded`, `empty`, and `failed` states.
- **Domain:** App models, repository protocols, and activity-scoring rules. It does not depend on SwiftUI or networking.
- **DataLayer:** API endpoints, response models (DTOs), data conversion, and repository implementations.
- **Utility:** Shared networking, cache, endpoints, and reusable view-state components.
- **AppContainer:** Creates and connects the real services, cached repositories, or test stub repositories.

**Why this structure?** Each part has a clear job. The UI can change without rewriting scoring rules, and business logic can be tested without calling the network.

### Important design decisions

- Each Open-Meteo API host has its own `NetworkManager`.
- Base URLs are read from build settings through `Info.plist` (`GEOCODING_API_BASE_URL`, `FORECAST_API_BASE_URL`, `MARINE_API_BASE_URL`), so configurations can use different servers.
- Caching is added using wrapper repositories (`CachedWeatherForecastRepository` and `CachedMarineForecastRepository`), keeping the remote repositories simple.
- The scoring engine is deterministic: the same input always produces the same score and ranking.
- City search waits **500 ms** after typing stops. A new search cancels the previous one to prevent older results from replacing newer results.

## 4. End-to-end app flow

Example: a user searches for **Manali**.

1. **City search:** Geocoding returns matching cities, coordinates, and timezone.
2. **Get weather:** The Forecast API provides daily and hourly weather.
3. **Get marine data:** The Marine API provides wave height, wave period, and sea temperature for surfing.
4. **Normalize data:** API responses are converted into app models. Forecast days are grouped by the city's local date, not UTC.
5. **Score activities:** The scoring engine calculates a score, confidence, and explanation for each activity.
6. **Show ranking:** The UI sorts each day's available activities from highest score to lowest.

If marine data fails, surfing can be affected without failing the other activities. If the weather request fails, the app reports the weather error. A recent cached forecast may be used when a request fails.

## 5. API endpoints and data

| API | Endpoint | Purpose |
|---|---|---|
| Geocoding | `GET /v1/search?name=…&language=en&format=json` | Search cities |
| Forecast | `GET /v1/forecast?…&forecast_days=7&timezone=…` | Daily and hourly weather |
| Marine | `GET /v1/marine?…&forecast_days=7&timezone=…` | Wave height, wave period, sea temperature |

Important API behavior:
- The app requests only weather variables needed by its scoring rules.
- If no city matches, Geocoding may omit `results`; the app treats this as an empty result, not a network error.
- Requests include the city's timezone so days are grouped by local date.
- For inland coordinates, marine values may all be `null`; the app uses this to mark surfing as unavailable.

## 6. Activity scoring

Each factor is scored from 0–100 and combined using the weights in `ActivityScoringConfiguration.swift`.

| Activity | Factors and weights |
|---|---|
| **Skiing** | Snow 40%, temperature 20%, wind 20%, precipitation 10%, weather 10% |
| **Surfing** | Wave height 35%, wave period 25%, wind 25%, weather 10%, sea temperature 5% |
| **Outdoor sightseeing** | Precipitation 30%, temperature comfort 25%, sunshine 20%, wind 15%, weather 10% |
| **Indoor sightseeing** | Precipitation 30%, temperature extremes 25%, weather 25%, wind 10%, cloud cover 10%, plus a baseline score of 30 |

### Scoring rules to remember

- **Higher score means more suitable.** Scores range from 0 to 100.
- **Missing data is not zero.** The score uses available factors, and confidence becomes lower when data is missing.
- **Unavailable is different from zero.** If critical data is missing (such as snow data for skiing, wave data for surfing, or temperature/precipitation for outdoor sightseeing), the activity may be marked unavailable and is not ranked.
- **No snow:** Skiing scores 0 if there is no snow on the ground or in the forecast.
- **Bad weather:** Thunderstorms or freezing rain cap outdoor activity scores at 15, and the reason explains the hazard.
- **Indoor sightseeing is scored independently.** It is not simply `100 - outdoor score`; worse outdoor conditions can make indoor activities more suitable.
- **Ranking:** Activities are sorted by score, highest first. Ties are broken by activity name to keep ordering consistent.
- **Explanation:** The reason highlights the two strongest positive factors and the strongest negative factor.

Scores are recommendations, not safety ratings.

## 7. Caching and failures

- Weather data is cached in memory for **30 minutes**.
- Marine data is cached in memory for **60 minutes**.
- If a request fails, cached data up to **6 hours old** may be shown with a “Couldn't get a newer forecast” notice.
- The cache is in memory only, so it clears when the app closes.
- Pull-to-refresh within the cache period may return cached data instead of making a new request.

## 8. Testing

Run tests in Xcode with **⌘U**, or use:

```bash
xcodebuild test -project WeatherForecast.xcodeproj -scheme WeatherForecast -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

| Area | What is tested | Count |
|---|---|---:|
| City search view model | Minimum query length, trimming, loaded/empty/failed states, retry, debounce and cancellation, city → forecast location | 13 |
| Ranking view model | Load, empty and failed states, stale data, cancellation, load-once, refresh errors keep rankings | 11 |
| Scoring engine | Weather conditions, missing data, ties, score range | 20 |
| Normalizer | Timezone boundaries, incomplete arrays, unknown weather codes, marine data | 10 |
| Cache | Cache hits, expiry, stale fallback, six-hour limit, cancellation | 9 |
| Network manager | URL building, decoding, bad status, malformed JSON, offline, cancellation | 7 |
| Endpoints | Method, path and query for Geocoding, Forecast and Marine; encoding; headers | 6 |
| City search response | Missing `results`, malformed cities dropped, mapping to `City` | 4 |
| Service | Marine failure isolation and weather failure | 2 |
| Error messages | User-facing text for every network error | 2 |
| Configuration | Base URLs from build settings | 1 |
| **Unit tests total** | | **85** |
| UI tests | Search results, empty/error states, ranking order, navigation | 8 |

Unit tests replace dependencies with mocks (`MockCityRepository`, `MockActivityRankingService`, `MockURLProtocol`), and UI tests use `-UITestScenario success|empty|failure` and stub repositories through `AppContainer`. No test relies on a live network.

## 9. Assumptions and limitations

- Surfing uses the selected city's coordinates, which may not be a real surf break. Surfing confidence is therefore capped at Moderate.
- Snow data does not confirm whether a ski resort is open, so skiing confidence is capped at Moderate.
- Daytime is **07:00–19:59 local time** for cloud cover, visibility, surf wind, and waves.
- Units are metric (°C, km/h, meters), and text is English-only.
- The app does not use wind direction, tides, or resort/attraction opening data.
- City search navigates directly to the ranking screen, which keeps the flow simple but connects the two features.

## 10. Before production

- Check Open-Meteo's terms: commercial use may require a paid plan.
- Add disk caching, offline support, and retry with backoff.
- Add broader logging, crash reporting, and analytics.
- Add localization, imperial units, and a full accessibility review.
- Tune scoring weights using user feedback, ideally through remote configuration.
- Add CI to run tests automatically and a staging configuration using separate API base URLs.

## 11. Build and run

1. Open `WeatherForecast.xcodeproj` in Xcode 16.2 or later.
2. Select the **WeatherForecast** scheme and an iPhone simulator.
3. Press **⌘R**.

No API keys or additional setup are needed.

## 12. Cross-platform and AI notes

- The Domain and DataLayer do not depend on SwiftUI/UIKit, so they may be reused for other Apple platforms with new views. The scoring engine could also support watchOS or widgets.
- For Android, the scoring logic could be ported to Kotlin, shared with Kotlin Multiplatform, or moved to a backend so all clients use the same rules.
- The project was developed with Claude Code as a pair-programming assistant, using an existing ProductList project as an architectural reference. AI helped with scaffolding, scoring implementation, tests, simulator checks, and simplification; the developer reviewed and directed the work.

# WeatherForecast
