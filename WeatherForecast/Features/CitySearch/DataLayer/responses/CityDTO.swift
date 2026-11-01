//
//  CityDTO.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Mirrors one result in the Open-Meteo geocoding response. Map to `City` before leaving the data layer.
struct CityDTO: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let admin1: String?
    let country: String?
    let timezone: String?
}

extension CityDTO {
    func toDomain() -> City {
        City(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            region: admin1,
            country: country,
            timezone: timezone
        )
    }
}
