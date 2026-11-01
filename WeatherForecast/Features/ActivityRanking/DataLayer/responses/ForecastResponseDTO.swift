//
//  ForecastResponseDTO.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Mirrors the Open-Meteo Forecast API response. `ForecastNormalizer` turns it into `DailyWeatherInput`.
/// Arrays are parallel: index `i` of every daily array refers to `daily.time[i]`.
/// Each array and each value can be missing, so lengths are checked before indexing.
struct ForecastResponseDTO: Decodable {
    let timezone: String?
    let utcOffsetSeconds: Int?
    let daily: DailyForecastDTO?
    let hourly: HourlyForecastDTO?

    private enum CodingKeys: String, CodingKey {
        case timezone
        case utcOffsetSeconds = "utc_offset_seconds"
        case daily
        case hourly
    }
}

struct DailyForecastDTO: Decodable {
    /// Local dates, such as "2026-11-01".
    let time: [String]
    let weatherCode: [Int?]?
    let temperatureMax: [Double?]?
    let temperatureMin: [Double?]?
    let apparentTemperatureMax: [Double?]?
    let precipitationProbabilityMax: [Double?]?
    let precipitationSum: [Double?]?
    let snowfallSum: [Double?]?
    let sunshineDuration: [Double?]?
    let windSpeedMax: [Double?]?
    let windGustsMax: [Double?]?

    private enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case precipitationSum = "precipitation_sum"
        case snowfallSum = "snowfall_sum"
        case sunshineDuration = "sunshine_duration"
        case windSpeedMax = "wind_speed_10m_max"
        case windGustsMax = "wind_gusts_10m_max"
    }
}

struct HourlyForecastDTO: Decodable {
    /// Local timestamps, such as "2026-11-01T13:00".
    let time: [String]
    let snowfall: [Double?]?
    let snowDepth: [Double?]?
    let cloudCover: [Double?]?
    let visibility: [Double?]?
    let windSpeed: [Double?]?
    let windGusts: [Double?]?

    private enum CodingKeys: String, CodingKey {
        case time
        case snowfall
        case snowDepth = "snow_depth"
        case cloudCover = "cloud_cover"
        case visibility
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
    }
}
