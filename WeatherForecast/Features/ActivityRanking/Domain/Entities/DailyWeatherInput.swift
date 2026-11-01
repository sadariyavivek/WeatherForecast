//
//  DailyWeatherInput.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// One local forecast date, normalized from the Forecast API.
/// Every value is optional: `nil` means the forecast didn't include it, never zero.
struct DailyWeatherInput: Equatable, Sendable {
    /// Local midnight in the forecast's timezone.
    let date: Date
    /// `nil` when the code is missing or unknown. Never treated as clear weather.
    let condition: WeatherCondition?
    let temperatureMax: Double?             // °C
    let temperatureMin: Double?             // °C
    let apparentTemperatureMax: Double?     // °C
    let precipitationProbabilityMax: Double? // %
    let precipitationSum: Double?           // mm
    let snowfallSum: Double?                // cm
    let sunshineDuration: Double?           // seconds
    let windSpeedMax: Double?               // km/h
    let windGustsMax: Double?               // km/h

    // Aggregated from hourly values for this local date.
    let snowDepthMax: Double?               // m, existing cover
    let hourlySnowfallSum: Double?          // cm, new accumulation
    let daytimeCloudCoverAverage: Double?   // %
    let daytimeVisibilityMin: Double?       // m
    let daytimeWindSpeedAverage: Double?    // km/h
    let daytimeWindGustsMax: Double?        // km/h

    var sunshineHours: Double? { sunshineDuration.map { $0 / 3600 } }
}

/// One local forecast date, normalized from the Marine API.
struct DailyMarineInput: Equatable, Sendable {
    /// Local midnight in the forecast's timezone.
    let date: Date
    /// Median significant wave height during daytime hours, in meters.
    let waveHeight: Double?
    /// Median wave period during daytime hours, in seconds. Falls back to the swell period.
    let wavePeriod: Double?
    /// Mean sea temperature during daytime hours, in °C.
    let seaSurfaceTemperature: Double?
    /// Share of daytime hours with a wave height reading, from 0 to 1.
    let hourlyCoverage: Double
}
