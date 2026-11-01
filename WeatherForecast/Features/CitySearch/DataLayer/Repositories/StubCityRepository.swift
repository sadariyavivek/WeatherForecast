//
//  StubCityRepository.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
#if DEBUG
import Foundation

/// Canned responses for SwiftUI previews and UI tests. Debug builds only.
/// UI tests pick a scenario with the launch arguments `-UITestScenario <success|empty|failure>`.
struct StubCityRepository: CityRepository {
    enum Scenario: String {
        case success
        case empty
        case failure
    }

    static let launchArgument = "-UITestScenario"

    static let sampleCities = [
        City(
            id: 2950159,
            name: "Berlin",
            latitude: 52.52437,
            longitude: 13.41053,
            region: "State of Berlin",
            country: "Germany",
            timezone: "Europe/Berlin"
        ),
        City(
            id: 5083330,
            name: "Berlin",
            latitude: 44.46867,
            longitude: -71.18508,
            region: "New Hampshire",
            country: "United States",
            timezone: "America/New_York"
        )
    ]

    let scenario: Scenario

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    /// Returns `nil` when the app wasn't launched with a stub scenario.
    init?(launchArguments: [String]) {
        guard let index = launchArguments.firstIndex(of: Self.launchArgument),
              launchArguments.indices.contains(index + 1),
              let scenario = Scenario(rawValue: launchArguments[index + 1]) else {
            return nil
        }
        self.init(scenario: scenario)
    }

    func searchCities(name: String) async throws -> [City] {
        switch scenario {
        case .success:
            return Self.sampleCities
        case .empty:
            return []
        case .failure:
            throw NetworkError.transport(.notConnectedToInternet)
        }
    }
}
#endif
