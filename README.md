# Coingecko

An iOS app that shows the Bitcoin price in EUR for the last 14 days, including today, using the [CoinGecko API](https://www.coingecko.com/en/api). Today's price updates every 60 seconds. Tapping a day opens a detail screen with the price in EUR, USD and GBP.

## Requirements

- Xcode 26 or later
- iOS 17 or later
- No third-party dependencies

## Getting started

1. Clone the repository and open `Coingecko.xcodeproj`.
2. Optional: add a CoinGecko Demo API key. The app works without one, but the public API has a stricter rate limit.
   ```bash
   cp Coingecko/Core/Config/Secrets/Secrets.xcconfig.example Coingecko/Core/Config/Secrets/Secrets.xcconfig
   ```
   Replace `your-demo-api-key` in the copied file with your key. `Secrets.xcconfig` is gitignored. If you don't add a key, leave the file out entirely; don't keep the placeholder value, or CoinGecko will reject the requests.
3. Run the `Coingecko` scheme on a simulator or device.

## Features

- **Price list:** the last 14 days of BTC/EUR, newest first. Today's row is marked **Live**, shows the time of its price, and refreshes every 60 seconds while the app is in the foreground.
- **Stale indicator:** today's row switches to **Stale(!)** when an update fails or CoinGecko's price is more than 5 minutes old.
- **Price detail:** EUR, USD and GBP for the selected day. Today uses the current price; past days use the price at 00:00 UTC.
- **States:** loading placeholders, an error screen with retry, an empty state, and pull-to-refresh. If a refresh fails while prices are on screen, the prices stay and a warning appears under the list.

## Architecture

MVVM with a service layer, built with SwiftUI, Observation and Swift Concurrency.

```
View  →  ViewModel  →  CGBitcoinPriceService  →  CGAPIClient  →  URLSession
                              ↓
                     CGCache, CGDateProvider
```

- **Views** (`UI/Modules/*/View`, `Subviews`) only render. They receive ready-to-display row models (`*BindableData`) with formatted text.
- **View models** (`@Observable`, main actor) own the screen state (`CGViewState`), formatting, live updates and cancellation.
- **`CGBitcoinPriceService`** turns CoinGecko responses into domain models (`CGDailyPrice`). It groups the history into days, validates prices and caches past days.
- **`CGAPIClient`** builds requests, attaches the API key and maps HTTP and transport errors.
- **`CGAppDependencies`** is the composition root. Dependencies are passed through initializers behind protocols (`CGBitcoinPriceServiceType`, `CGAPIClientType`, `CGCacheType`, `CGDateProviderType`), so tests and previews can replace them.

### CoinGecko endpoints

| Purpose | Endpoint |
|---|---|
| 14-day list | `/coins/bitcoin/market_chart?vs_currency=eur&days=14&interval=daily` |
| Today's live price, today's detail | `/simple/price?ids=bitcoin&vs_currencies=…&include_last_updated_at=true` |
| A past day's detail | `/coins/bitcoin/history?date=dd-MM-yyyy` (cached in memory) |

### Concurrency

- The list runs a single task for all loading: the 60-second live loop and pull-to-refresh share it. Starting one cancels the other, so there are never two loaders writing the same state.
- Live updates run only while the scene is active. Going to the background cancels the loop, including a pull-to-refresh in progress, and returning to the foreground restarts it.
- Every result is checked for cancellation after the request returns, so a cancelled or replaced request can't overwrite newer data.

## Decisions and trade-offs

- **Days are UTC days.** CoinGecko's daily prices are taken at 00:00 UTC, so the list groups prices by UTC day and labels them in UTC. For users far from UTC this means "today" can differ from their local date. For example, at 21:00 in New York the top row already shows the next day.
- **Past days show the 00:00 UTC price** on both the list and the detail screen. The two screens use different endpoints; in testing they return identical prices, but CoinGecko doesn't document that they always will.
- **Missing days are shown as missing.** If CoinGecko returns fewer than 14 days, the list shows the days it has instead of failing completely. History points with an invalid price (zero, negative or non-finite) or an invalid timestamp are skipped. An invalid price on the live or detail requests is reported as an error instead of being shown.
- **Timestamps more than 60 seconds in the future are rejected.** A future timestamp would make a price look fresh indefinitely. The 60-second allowance covers small differences between the device clock and CoinGecko's.
- **Today's price is only replaced by a newer one.** A live update that is older than the price on screen is ignored. If the UTC day changes while a live update is in flight, the list reloads the history instead.
- **Midnight UTC while the app is open:** the rows are recalculated on the next 60-second update, so yesterday's row can keep its Live badge for up to a minute after midnight.
- **Freshness depends on CoinGecko.** On the free API, prices are usually 20–120 seconds old when they arrive. That's why "Stale(!)" uses a 5-minute limit rather than 60 seconds.
- **Today's detail screen is fetched once** when it opens and doesn't live-update, so it can differ slightly from the list's live price.
- **Past-day prices are cached in memory only** (`NSCache`), and only when all three currencies are present.
- **The API key ships inside the app bundle** (via `Info.plist`), so anyone with the app can read it. That's acceptable for a CoinGecko Demo key but not for a paid key, which would need a backend proxy.

## Tests

Run all tests with ⌘U, or from the command line:

```bash
xcodebuild test -project Coingecko.xcodeproj -scheme Coingecko \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

- **Unit tests** (`CoingeckoTests/Services`, `ViewModels`) cover the price service's day grouping and validation, the API client, endpoints, cache, date provider and both view models. Mocks are in `CoingeckoTests/Mocks`.
- **Integration tests** (`CoingeckoTests/Integration`) run the real API client, service, cache and view models against fake network responses (`CGURLProtocolStub`).
- **UI test** (`CoingeckoUITests`) opens a past day and checks its EUR, USD and GBP prices.

All tests are deterministic: no real network requests, and a fixed clock. The UI test launches the app with `-ui-testing`, which, in Debug builds only, replaces the network with fixture data and fixes the date to Oct 13, 2026.

## Possible improvements

- Throttle the immediate update when returning to the foreground, so quickly switching apps doesn't send several requests.
- Clearer messages for timeouts and invalid API keys (currently a generic error).
- Better VoiceOver labels and large Dynamic Type layout for today's row.
- Persist past-day prices on disk so they survive restarts.
