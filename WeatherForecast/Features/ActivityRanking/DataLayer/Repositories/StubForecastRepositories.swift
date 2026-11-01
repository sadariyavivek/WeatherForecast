//
//  StubForecastRepositories.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
#if DEBUG
import Foundation

/// Canned forecasts for SwiftUI previews and UI tests. Debug builds only.
/// UI tests pick a scenario with the launch arguments `-UITestScenario <success|empty|failure>`.
struct StubWeatherForecastRepository: WeatherForecastRepository {
    enum Scenario: String {
        case success
        case empty
        case failure
    }

    static let launchArgument = "-UITestScenario"
    static let timeZone = TimeZone(identifier: "Europe/Lisbon")!

    let scenario: Scenario

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    /// Returns `nil` when the app wasn't launched with a stub scenario.
    init?(launchArguments: [String]) {
        guard let index = launchArguments.firstIndex(of: Self.launchArgument),
              launchArguments.indices.contains(index + 1),
              let scenario = Scenario(rawValue: launchArguments[index + 1]) else {
            return nil
        }
        self.init(scenario: scenario)
    }

    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast {
        switch scenario {
        case .success:
            return WeatherForecast(timeZone: Self.timeZone, days: Self.sampleDays)
        case .empty:
            return WeatherForecast(timeZone: Self.timeZone, days: [])
        case .failure:
            throw NetworkError.transport(.notConnectedToInternet)
        }
    }

    /// Local midnight `offset` days from today in `timeZone`.
    static func day(_ offset: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now))!
    }

    /// A sunny day, a rainy day, a snowy day and a thunderstorm.
    static let sampleDays = [
        DailyWeatherInput(
            date: day(0), condition: .mainlyClear,
            temperatureMax: 23, temperatureMin: 14, apparentTemperatureMax: 22,
            precipitationProbabilityMax: 5, precipitationSum: 0, snowfallSum: 0,
            sunshineDuration: 9 * 3600, windSpeedMax: 12, windGustsMax: 25,
            snowDepthMax: 0, hourlySnowfallSum: 0, daytimeCloudCoverAverage: 15,
            daytimeVisibilityMin: 24_000, daytimeWindSpeedAverage: 9, daytimeWindGustsMax: 22
        ),
        DailyWeatherInput(
            date: day(1), condition: .moderateRain,
            temperatureMax: 14, temperatureMin: 10, apparentTemperatureMax: 12,
            precipitationProbabilityMax: 90, precipitationSum: 12, snowfallSum: 0,
            sunshineDuration: 600, windSpeedMax: 30, windGustsMax: 55,
            snowDepthMax: 0, hourlySnowfallSum: 0, daytimeCloudCoverAverage: 95,
            daytimeVisibilityMin: 6_000, daytimeWindSpeedAverage: 24, daytimeWindGustsMax: 50
        ),
        DailyWeatherInput(
            date: day(2), condition: .moderateSnowfall,
            temperatureMax: -3, temperatureMin: -9, apparentTemperatureMax: -7,
            precipitationProbabilityMax: 60, precipitationSum: 4, snowfallSum: 8,
            sunshineDuration: 3 * 3600, windSpeedMax: 15, windGustsMax: 30,
            snowDepthMax: 0.6, hourlySnowfallSum: 8, daytimeCloudCoverAverage: 70,
            daytimeVisibilityMin: 3_000, daytimeWindSpeedAverage: 12, daytimeWindGustsMax: 28
        ),
        DailyWeatherInput(
            date: day(3), condition: .thunderstorm,
            temperatureMax: 27, temperatureMin: 19, apparentTemperatureMax: 29,
            precipitationProbabilityMax: 80, precipitationSum: 18, snowfallSum: 0,
            sunshineDuration: 2 * 3600, windSpeedMax: 35, windGustsMax: 70,
            snowDepthMax: 0, hourlySnowfallSum: 0, daytimeCloudCoverAverage: 85,
            daytimeVisibilityMin: 4_000, daytimeWindSpeedAverage: 25, daytimeWindGustsMax: 65
        )
    ]
}

/// Good surf on every sample day, matching `StubWeatherForecastRepository.sampleDays`.
struct StubMarineForecastRepository: MarineForecastRepository {
    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        StubWeatherForecastRepository.sampleDays.map { day in
            DailyMarineInput(
                date: day.date,
                waveHeight: 1.6,
                wavePeriod: 12,
                seaSurfaceTemperature: 17,
                hourlyCoverage: 1
            )
        }
    }
}
#endif
