//
//  MockCityRepository.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
@testable import WeatherForecast

// Tests touch the mock only from the main actor, one test at a time.
final class MockCityRepository: CityRepository, @unchecked Sendable {
    var searchHandler: (String) async throws -> [City]
    private(set) var searchedNames: [String] = []

    init(result: Result<[City], Error>) {
        self.searchHandler = { _ in try result.get() }
    }

    func searchCities(name: String) async throws -> [City] {
        searchedNames.append(name)
        return try await searchHandler(name)
    }
}

extension City {
    static func stub(
        id: Int = 2950159,
        name: String = "Berlin",
        latitude: Double = 52.52437,
        longitude: Double = 13.41053,
        region: String? = "State of Berlin",
        country: String? = "Germany",
        timezone: String? = "Europe/Berlin"
    ) -> City {
        City(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            region: region,
            country: country,
            timezone: timezone
        )
    }
}
