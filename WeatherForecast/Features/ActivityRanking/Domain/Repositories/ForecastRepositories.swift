//
//  ForecastRepositories.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// A normalized seven-day forecast: one record per local date.
struct WeatherForecast: Equatable, Sendable {
    let timeZone: TimeZone
    let days: [DailyWeatherInput]
    /// When this forecast came from the API.
    let fetchedAt: Date
    /// `true` when a request failed and this older cached forecast was served instead.
    let isStale: Bool

    init(timeZone: TimeZone, days: [DailyWeatherInput], fetchedAt: Date = .now, isStale: Bool = false) {
        self.timeZone = timeZone
        self.days = days
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }
}

/// Owned by the domain so the presentation layer never depends on the data layer.
protocol WeatherForecastRepository: Sendable {
    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast
}

protocol MarineForecastRepository: Sendable {
    /// Uses the location's timezone, like the weather request, so both group hours into the same local dates.
    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput]
}
