//
//  CityRepository.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Owned by the domain so the presentation layer never depends on the data layer.
protocol CityRepository: Sendable {
    func searchCities(name: String) async throws -> [City]
}
