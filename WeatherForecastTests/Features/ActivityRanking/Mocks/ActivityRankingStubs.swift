//
//  ActivityRankingStubs.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation
@testable import WeatherForecast

extension DailyWeatherInput {
    static let stubDate = Date(timeIntervalSince1970: 1_793_491_200)

    /// A dry, sunny, comfortable day with no snow. Tests override only what they're about.
    static func stub(
        date: Date = stubDate,
        condition: WeatherCondition? = .mainlyClear,
        temperatureMax: Double? = 23,
        temperatureMin: Double? = 14,
        apparentTemperatureMax: Double? = 22,
        precipitationProbabilityMax: Double? = 5,
        precipitationSum: Double? = 0,
        snowfallSum: Double? = 0,
        sunshineDuration: Double? = 9 * 3600,
        windSpeedMax: Double? = 12,
        windGustsMax: Double? = 25,
        snowDepthMax: Double? = 0,
        hourlySnowfallSum: Double? = 0,
        daytimeCloudCoverAverage: Double? = 15,
        daytimeVisibilityMin: Double? = 24_000,
        daytimeWindSpeedAverage: Double? = 9,
        daytimeWindGustsMax: Double? = 22
    ) -> DailyWeatherInput {
        DailyWeatherInput(
            date: date,
            condition: condition,
            temperatureMax: temperatureMax,
            temperatureMin: temperatureMin,
            apparentTemperatureMax: apparentTemperatureMax,
            precipitationProbabilityMax: precipitationProbabilityMax,
            precipitationSum: precipitationSum,
            snowfallSum: snowfallSum,
            sunshineDuration: sunshineDuration,
            windSpeedMax: windSpeedMax,
            windGustsMax: windGustsMax,
            snowDepthMax: snowDepthMax,
            hourlySnowfallSum: hourlySnowfallSum,
            daytimeCloudCoverAverage: daytimeCloudCoverAverage,
            daytimeVisibilityMin: daytimeVisibilityMin,
            daytimeWindSpeedAverage: daytimeWindSpeedAverage,
            daytimeWindGustsMax: daytimeWindGustsMax
        )
    }

    static func rainyStub(date: Date = stubDate) -> DailyWeatherInput {
        .stub(
            date: date,
            condition: .moderateRain,
            temperatureMax: 14,
            temperatureMin: 10,
            apparentTemperatureMax: 12,
            precipitationProbabilityMax: 90,
            precipitationSum: 12,
            sunshineDuration: 600,
            windSpeedMax: 30,
            windGustsMax: 55,
            daytimeCloudCoverAverage: 95
        )
    }
}

extension DailyMarineInput {
    /// Good surf: chest-to-head-high waves with a long period.
    static func stub(
        date: Date = DailyWeatherInput.stubDate,
        waveHeight: Double? = 1.6,
        wavePeriod: Double? = 12,
        seaSurfaceTemperature: Double? = 17,
        hourlyCoverage: Double = 1
    ) -> DailyMarineInput {
        DailyMarineInput(
            date: date,
            waveHeight: waveHeight,
            wavePeriod: wavePeriod,
            seaSurfaceTemperature: seaSurfaceTemperature,
            hourlyCoverage: hourlyCoverage
        )
    }
}

extension DailyActivityRanking {
    func score(for activity: Activity) -> ActivityScore? {
        (rankedActivities + unavailableActivities).first { $0.activity == activity }
    }

    var rankedOrder: [Activity] {
        rankedActivities.map(\.activity)
    }
}
