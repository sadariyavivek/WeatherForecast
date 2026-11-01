//
//  EndpointTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

/// Checks every Open-Meteo request the app sends: method, path and query parameters.
final class EndpointTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/v1")!

    private func query(of endpoint: some Endpoint) throws -> (request: URLRequest, items: [String: String]) {
        let request = try endpoint.urlRequest(relativeTo: baseURL)
        let components = try XCTUnwrap(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        return (request, items)
    }

    // MARK: - Geocoding

    func test_searchCities_isGETWithNameQuery() throws {
        let (request, items) = try query(of: GeocodingEndpoint.searchCities(name: "Berlin"))

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/search")
        XCTAssertEqual(items, ["name": "Berlin", "language": "en", "format": "json"])
        XCTAssertNil(request.httpBody)
    }

    func test_searchCities_percentEncodesTheName() throws {
        let request = try GeocodingEndpoint.searchCities(name: "São Paulo & co").urlRequest(relativeTo: baseURL)

        XCTAssertTrue(request.url?.absoluteString.contains("name=S%C3%A3o%20Paulo%20%26%20co") ?? false)
    }

    // MARK: - Forecast

    func test_forecast_requestsSevenDaysOfScoringVariablesInTheCitysTimezone() throws {
        let (request, items) = try query(
            of: ForecastEndpoint.sevenDayForecast(latitude: 52.52, longitude: 13.41, timezone: "Europe/Berlin")
        )

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/forecast")
        XCTAssertEqual(items["latitude"], "52.52")
        XCTAssertEqual(items["longitude"], "13.41")
        XCTAssertEqual(items["forecast_days"], "7")
        XCTAssertEqual(items["timezone"], "Europe/Berlin")
        XCTAssertEqual(items["daily"], ForecastEndpoint.dailyFields.joined(separator: ","))
        XCTAssertEqual(items["hourly"], ForecastEndpoint.hourlyFields.joined(separator: ","))
    }

    func test_forecast_withoutTimezone_asksAPIToPickOne() throws {
        let (_, items) = try query(of: ForecastEndpoint.sevenDayForecast(latitude: 0, longitude: 0, timezone: nil))

        XCTAssertEqual(items["timezone"], "auto")
    }

    // MARK: - Marine

    func test_marine_requestsSevenDaysOfWaveVariables() throws {
        let (request, items) = try query(
            of: MarineEndpoint.sevenDayForecast(latitude: 38.7, longitude: -9.1, timezone: "Europe/Lisbon")
        )

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/marine")
        XCTAssertEqual(items["forecast_days"], "7")
        XCTAssertEqual(items["timezone"], "Europe/Lisbon")
        XCTAssertEqual(items["hourly"], "wave_height,wave_period,swell_wave_period,sea_surface_temperature")
    }

    // MARK: - Headers

    func test_everyRequest_acceptsJSON() throws {
        let endpoints: [any Endpoint] = [
            GeocodingEndpoint.searchCities(name: "Berlin"),
            ForecastEndpoint.sevenDayForecast(latitude: 0, longitude: 0, timezone: nil),
            MarineEndpoint.sevenDayForecast(latitude: 0, longitude: 0, timezone: nil)
        ]

        for endpoint in endpoints {
            let request = try endpoint.urlRequest(relativeTo: baseURL)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json", "\(endpoint)")
        }
    }
}
