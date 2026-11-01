//
//  GeocodingEndpoint.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
enum GeocodingEndpoint: Endpoint {
    case searchCities(name: String)

    var path: String {
        switch self {
        case .searchCities:
            return "/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .searchCities:
            return .get
        }
    }

    var parameters: Parameters {
        switch self {
        case .searchCities(let name):
            return ["name": name, "language": "en", "format": "json"]
        }
    }
}
