//
//  ForecastEndpoint.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Open-Meteo Forecast API, served from `APIBaseURL.forecast`.
enum ForecastEndpoint: Endpoint {
    case sevenDayForecast(latitude: Double, longitude: Double, timezone: String?)

    static let forecastDays = 7

    static let dailyFields = [
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "apparent_temperature_max",
        "precipitation_probability_max",
        "precipitation_sum",
        "snowfall_sum",
        "sunshine_duration",
        "wind_speed_10m_max",
        "wind_gusts_10m_max"
    ]

    static let hourlyFields = [
        "snowfall",
        "snow_depth",
        "cloud_cover",
        "visibility",
        "wind_speed_10m",
        "wind_gusts_10m"
    ]

    var path: String {
        switch self {
        case .sevenDayForecast:
            return "/forecast"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .sevenDayForecast:
            return .get
        }
    }

    var parameters: Parameters {
        switch self {
        case .sevenDayForecast(let latitude, let longitude, let timezone):
            return [
                "latitude": latitude,
                "longitude": longitude,
                "daily": Self.dailyFields.joined(separator: ","),
                "hourly": Self.hourlyFields.joined(separator: ","),
                "forecast_days": Self.forecastDays,
                // A named timezone makes every timestamp in the response local to the destination.
                "timezone": timezone ?? "auto"
            ]
        }
    }
}
