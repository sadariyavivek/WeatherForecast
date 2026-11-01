//
//  ActivityRankingService.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import OSLog

protocol ActivityRankingServiceProtocol: Sendable {
    func rankActivities(for location: ForecastLocation) async throws -> ActivityForecast
}

/// Fetches the weather and marine forecasts together, then scores and ranks every day.
struct ActivityRankingService: ActivityRankingServiceProtocol {
    private static let logger = Logger(subsystem: "WeatherForecast", category: "ActivityRanking")

    private let weatherRepository: WeatherForecastRepository
    private let marineRepository: MarineForecastRepository
    private let engine: ActivityScoringEngine

    init(
        weatherRepository: WeatherForecastRepository,
        marineRepository: MarineForecastRepository,
        engine: ActivityScoringEngine = ActivityScoringEngine()
    ) {
        self.weatherRepository = weatherRepository
        self.marineRepository = marineRepository
        self.engine = engine
    }

    func rankActivities(for location: ForecastLocation) async throws -> ActivityForecast {
        async let marine = marineForecast(for: location)
        let weather = try await weatherRepository.weatherForecast(for: location)
        let marineDays = try await marine

        let days = engine.rankActivities(forecasts: weather.days, marineForecasts: marineDays)
        return ActivityForecast(
            timeZone: weather.timeZone,
            days: days,
            fetchedAt: weather.fetchedAt,
            isStale: weather.isStale
        )
    }

    /// Surfing is one of four activities, so a marine failure leaves surfing unavailable
    /// instead of failing the whole screen.
    private func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        do {
            return try await marineRepository.marineForecast(for: location)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Self.logger.error("Marine forecast failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }
}
