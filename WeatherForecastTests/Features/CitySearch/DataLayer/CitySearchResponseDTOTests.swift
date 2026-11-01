//
//  CitySearchResponseDTOTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class CitySearchResponseDTOTests: XCTestCase {

    private func decode(_ json: String) throws -> CitySearchResponseDTO {
        try JSONDecoder().decode(CitySearchResponseDTO.self, from: Data(json.utf8))
    }

    func test_missingResultsKey_meansNoCities() throws {
        // Open-Meteo leaves out `results` entirely when nothing matches.
        let response = try decode(#"{"generationtime_ms": 0.07}"#)

        XCTAssertTrue(response.results.isEmpty)
    }

    func test_malformedCity_isDropped_andTheRestKept() throws {
        let response = try decode("""
        {"results": [
          {"id": 1, "name": "Berlin", "latitude": 52.5, "longitude": 13.4},
          {"id": 2, "name": "Missing coordinates"}
        ]}
        """)

        XCTAssertEqual(response.results.map(\.id), [1])
    }

    func test_toDomain_mapsAPIFieldsToCity() throws {
        let response = try decode("""
        {"results": [{
          "id": 2950159, "name": "Berlin", "latitude": 52.52437, "longitude": 13.41053,
          "admin1": "State of Berlin", "country": "Germany", "timezone": "Europe/Berlin",
          "population": 3426354
        }]}
        """)

        XCTAssertEqual(response.results.first?.toDomain(), .stub())
    }

    func test_toDomain_withoutOptionalFields_leavesThemNil() throws {
        let response = try decode(#"{"results": [{"id": 7, "name": "Atlantis", "latitude": 0, "longitude": 0}]}"#)

        let city = try XCTUnwrap(response.results.first?.toDomain())
        XCTAssertNil(city.region)
        XCTAssertNil(city.country)
        XCTAssertNil(city.timezone)
    }
}
