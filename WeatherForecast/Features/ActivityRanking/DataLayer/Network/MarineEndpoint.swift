//
//  MarineEndpoint.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Open-Meteo Marine API, served from `APIBaseURL.marine`.
enum MarineEndpoint: Endpoint {
    case sevenDayForecast(latitude: Double, longitude: Double, timezone: String?)

    static let hourlyFields = [
        "wave_height",
        "wave_period",
        "swell_wave_period",
        "sea_surface_temperature"
    ]

    var path: String {
        switch self {
        case .sevenDayForecast:
            return "/marine"
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
                "hourly": Self.hourlyFields.joined(separator: ","),
                "forecast_days": ForecastEndpoint.forecastDays,
                "timezone": timezone ?? "auto"
            ]
        }
    }
}
