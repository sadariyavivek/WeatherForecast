//
//  CachedForecastRepositories.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

extension CachePolicy {
    /// Open-Meteo updates its models about hourly, so a newer request would rarely differ.
    static let weather = CachePolicy(freshFor: 30 * 60, usableAfterErrorFor: 6 * 60 * 60)
    /// Wave models update less often than weather models.
    static let marine = CachePolicy(freshFor: 60 * 60, usableAfterErrorFor: 6 * 60 * 60)
}

/// Coordinates rounded to 0.01° (about 1 km), well inside one Open-Meteo grid cell,
/// so the same city picked twice shares an entry.
struct ForecastCacheKey: Hashable, Sendable {
    let latitude: Int
    let longitude: Int
    let timezone: String?

    init(_ location: ForecastLocation) {
        latitude = Int((location.latitude * 100).rounded())
        longitude = Int((location.longitude * 100).rounded())
        timezone = location.timezone
    }
}

/// Wraps another weather repository with `CachePolicy.weather`.
/// A forecast served after a failed request is marked stale, so the screen can say it's showing older data.
final class CachedWeatherForecastRepository: WeatherForecastRepository {
    private let base: WeatherForecastRepository
    private let now: @Sendable () -> Date
    private let cache: ExpiringCache<ForecastCacheKey, WeatherForecast>

    init(
        wrapping base: WeatherForecastRepository,
        policy: CachePolicy = .weather,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.base = base
        self.now = now
        cache = ExpiringCache(policy: policy, now: now)
    }

    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast {
        let (forecast, isStale) = try await cache.value(for: ForecastCacheKey(location)) { [base] in
            try await base.weatherForecast(for: location)
        }
        return isStale ? forecast.servedStale(at: now()) : forecast
    }
}

/// Wraps another marine repository with `CachePolicy.marine`.
/// No stale marking: days that have passed are never matched to a weather date.
final class CachedMarineForecastRepository: MarineForecastRepository {
    private let base: MarineForecastRepository
    private let cache: ExpiringCache<ForecastCacheKey, [DailyMarineInput]>

    init(
        wrapping base: MarineForecastRepository,
        policy: CachePolicy = .marine,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.base = base
        cache = ExpiringCache(policy: policy, now: now)
    }

    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        try await cache.value(for: ForecastCacheKey(location)) { [base] in
            try await base.marineForecast(for: location)
        }.value
    }
}

private extension WeatherForecast {
    /// This forecast marked stale, without days that ended before `date` in its own timezone.
    func servedStale(at date: Date) -> WeatherForecast {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: date)
        return WeatherForecast(
            timeZone: timeZone,
            days: days.filter { $0.date >= today },
            fetchedAt: fetchedAt,
            isStale: true
        )
    }
}
