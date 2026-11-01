//
//  MarineResponseDTO.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Mirrors the Open-Meteo Marine API response. Inland coordinates return every value as `null`.
struct MarineResponseDTO: Decodable {
    let timezone: String?
    let utcOffsetSeconds: Int?
    let hourly: HourlyMarineDTO?

    private enum CodingKeys: String, CodingKey {
        case timezone
        case utcOffsetSeconds = "utc_offset_seconds"
        case hourly
    }
}

struct HourlyMarineDTO: Decodable {
    /// Local timestamps, such as "2026-11-01T13:00".
    let time: [String]
    let waveHeight: [Double?]?
    let wavePeriod: [Double?]?
    /// Fallback when `wavePeriod` is mostly missing.
    let swellWavePeriod: [Double?]?
    let seaSurfaceTemperature: [Double?]?

    private enum CodingKeys: String, CodingKey {
        case time
        case waveHeight = "wave_height"
        case wavePeriod = "wave_period"
        case swellWavePeriod = "swell_wave_period"
        case seaSurfaceTemperature = "sea_surface_temperature"
    }
}
