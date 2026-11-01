//
//  MockActivityRankingService.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation
@testable import WeatherForecast

// Tests touch the mock only from the main actor, one test at a time.
final class MockActivityRankingService: ActivityRankingServiceProtocol, @unchecked Sendable {
    var handler: () async throws -> ActivityForecast
    private(set) var requestedLocations: [ForecastLocation] = []

    init(result: Result<ActivityForecast, Error>) {
        self.handler = { try result.get() }
    }

    func rankActivities(for location: ForecastLocation) async throws -> ActivityForecast {
        requestedLocations.append(location)
        return try await handler()
    }
}

extension ActivityForecast {
    /// A forecast with `dayCount` sunny days, scored by the real engine.
    static func stub(dayCount: Int = 1, isStale: Bool = false) -> ActivityForecast {
        let days = (0..<dayCount).map { offset in
            DailyWeatherInput.stub(date: DailyWeatherInput.stubDate.addingTimeInterval(Double(offset) * 86_400))
        }
        return ActivityForecast(
            timeZone: TimeZone(identifier: "Europe/Berlin")!,
            days: ActivityScoringEngine().rankActivities(forecasts: days, marineForecasts: []),
            fetchedAt: DailyWeatherInput.stubDate,
            isStale: isStale
        )
    }
}

extension ForecastLocation {
    static let berlin = ForecastLocation(
        name: "Berlin",
        latitude: 52.52437,
        longitude: 13.41053,
        timezone: "Europe/Berlin"
    )
}
